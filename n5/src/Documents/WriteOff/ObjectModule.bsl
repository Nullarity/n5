#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;
var Env;

Procedure Filling ( FillingData, FillingText, StandardProcessing )
	
	if ( TypeOf ( FillingData ) = Type ( "DocumentRef.Waybill" ) ) then
		fillByWaybill ( FillingData );
	endif;
	
EndProcedure

Procedure fillByWaybill ( FillingData )
	
	Base = FillingData;
	setEnv ();
	sqlFields ();
	getFields ();
	checkWaybill ();
	sqlWaybill ();
	getTables ();
	headerByWaybill ();
	itemsByWaybill ();
	
EndProcedure

Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure
	
Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Document.Company as Company, Document.Car as Car, Document.FuelInventory as FuelInventory,
	|	Document.Car.Warehouse as Warehouse, dateadd ( Document.Date, second, 1 ) as Date,
	|	Document.Account as ExpenseAccount, Document.Dim1 as Dim1, Document.Dim2 as Dim2,
	|	Document.Dim3 as Dim3, Document.Product as Product, Document.ProductFeature as ProductFeature
	|from Document.Waybill as Document
	|where Document.Ref = &Base
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ()
	
	SQL.Perform ( Env );
	
EndProcedure

Procedure checkWaybill ()
	
	if ( not Env.Fields.FuelInventory ) then
		raise Output.WaybillWriteOffError ();
	endif;
	
EndProcedure

Procedure sqlWaybill ()
	
	s = "
	|// #Items
	|select Items.Fuel as Item, Items.Fuel.Package as Package,
	|	isnull ( Items.Fuel.Package.Capacity, 1 ) as Capacity,
	|	case when Items.QuantityBalance < isnull ( Balances.QuantityBalance, 0 )
	|		then Items.QuantityBalance
	|		else isnull ( Balances.QuantityBalance, 0 )
	| 	end as Quantity
	|from AccumulationRegister.FuelToExpense.Balance ( &Date, Car = &Car ) as Items
	|	//
	|	// Balances
	|	//
	|	left join AccumulationRegister.Items.Balance ( &Date,
	|		Warehouse in ( select Warehouse from Catalog.Cars where Ref = &Car ) ) as Balances
	|	on Items.Fuel = Balances.Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ()
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Date", fields.Date );
	q.SetParameter ( "Car", fields.Car );
	SQL.Perform ( Env );	
	
EndProcedure

Procedure headerByWaybill ()
	
	FillPropertyValues ( ThisObject, Env.Fields );
	Currency = Application.Currency ();
	CarExpenses = Enums.CarExpenses.Fuel;
	
EndProcedure 

Procedure itemsByWaybill ()
	
	table = Env.Items;
	if ( table.Count () = 0 ) then
		raise Output.FillingDataNotFoundError ();
	endif;
	Items.Clear ();
	for each row in table do
		newRow = Items.Add ();
		FillPropertyValues ( newRow, row );
		accounts = AccountsMap.Item ( newRow.Item, Company, Warehouse, "Account, VAT" );
		newRow.Account = accounts.Account;
		newRow.VATAccount = accounts.VAT;
		Computations.Packages ( newRow );
	enddo;
	
EndProcedure

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkVAT ( CheckedAttributes );
	checkDriver ( CheckedAttributes );

EndProcedure

Procedure checkVAT ( CheckedAttributes )

	if ( VATUse > 0 ) then
		CheckedAttributes.Add ( "VATAccount" );
		CheckedAttributes.Add ( "Items.VATAccount" );
	endif; 
	
EndProcedure

Procedure checkDriver ( CheckedAttributes )
	
	if ( DF.Pick ( Warehouse, "Class" ) = Enums.WarehouseTypes.Car
		and CarExpenses = Enums.CarExpenses.Overconsumption ) then
		CheckedAttributes.Add ( "Items.Driver" );
	endif;
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
		return;
	endif;
	if ( not DeletionMark ) then
		InvoiceRecords.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Realtime = Realtime;
	Cancel = not Documents.WriteOff.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	BelongingToSequences.Cost.Clear ();
	
EndProcedure

#endif
