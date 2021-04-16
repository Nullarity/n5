#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Base;
var Env;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkQuantityBack () ) then
		Cancel = true;
	endif;
	
EndProcedure

Function checkQuantityBack ()
	
	error = false;
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in Items do
		if ( row.QuantityBack < 0 ) then
			Output.QuantityBackIncorrect ( , Output.Row ( "Items", row.LineNumber, column ) );
			error = true;
		endif; 
	enddo; 
	return not error;

EndFunction 

Procedure Filling ( FillingData, StandardProcessing )
	
	Base = FillingData;
	baseType = TypeOf ( Base );
	if ( baseType = Type ( "DocumentRef.SalesOrder" ) ) then
		fillBySalesOrder ();
	elsif ( baseType = Type ( "DocumentObject.Shipment" ) ) then
		fillByShipment ();
	endif;
	
EndProcedure

Procedure fillBySalesOrder ()
	
	setEnv ();
	sqlSalesOrder ();
	SQL.Perform ( Env );
	FillPropertyValues ( ThisObject, Env.Fields );
	Date = CurrentSessionDate ();
	Items.Load ( Env.Items );
	Services.Load ( Env.Services );
	adjustItems ();
	
EndProcedure

Procedure setEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	Env.Q.SetParameter ( "Base", Base );
	
EndProcedure

Procedure sqlSalesOrder ()
	
	s = "
	|// @Fields
	|select Documents.Amount as Amount, Documents.Company as Company, Documents.Contract as Contract,
	|	Documents.Creator as Creator, Documents.Currency as Currency,
	|	Documents.Customer as Customer, Documents.Discount as Discount, Documents.DeliveryDate as DeliveryDate,
	|	Documents.Factor as Factor, Documents.GrossAmount as GrossAmount,
	|	Documents.Prices as Prices, Documents.Rate as Rate, Documents.VATUse as VATUse, Documents.VAT as VAT,
	|	Documents.Warehouse as Warehouse, Documents.Ref as SalesOrder,
	|	Documents.Department as Department, Documents.Number as SO, Documents.PO as PO
	|from Document.SalesOrder as Documents
	|where Documents.Ref = &Base
	|;
	|// #Items
	|select Items.Feature as Feature, Items.DeliveryDate as DeliveryDate, Items.DiscountRate as DiscountRate, Items.Item as Item,
	|	Items.Package as PackagePlan, Items.Price as Price, Items.Prices as Prices, Items.Quantity as QuantityPlan,
	|	Items.QuantityPkg as QuantityPkgPlan, Items.Discount as Discount,
	|	Items.Capacity as CapacityPlan, Items.VAT as VAT, Items.VATCode as VATCode, Items.Total as Total,
	|	Items.VATRate as VATRate, Items.Amount as Amount, Items.Reservation as Reservation, Items.Stock as Stock,
	|	Items.RowKey as RowKey, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey
	|from Document.SalesOrder.Items as Items
	|where Items.Ref = &Base
	|order by Items.LineNumber
	|;
	|// #Services
	|select Services.Feature as Feature, Services.DeliveryDate as DeliveryDate, Services.DiscountRate as DiscountRate,
	|	Services.Item as Item, Services.Discount as Discount, Services.VAT as VAT, Services.VATCode as VATCode, 
	|	Services.VATRate as VATRate, Services.Total as Total,
	|	Services.Amount as Amount, Services.Price as Price, Services.Prices as Prices,
	|	Services.Quantity as Quantity, Services.Description as Description, Services.RowKey as RowKey
	|from Document.SalesOrder.Services as Services
	|where Services.Ref = &Base
	|order by Services.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure adjustItems ()
	
	for each row in Items do
		row.Capacity = row.CapacityPlan;
		row.Package = row.PackagePlan;
		row.QuantityBack = row.QuantityPlan;
		row.QuantityPkgBack = row.QuantityPlan;
	enddo; 
	
EndProcedure 

Procedure fillByShipment ()
	
	headerByShipment ();
	itemsByShipment ();
	
EndProcedure 

Procedure headerByShipment ()
	
	FillPropertyValues ( ThisObject, Base );
	Number = "";
	Memo = "";
	Date = CurrentSessionDate ();
	
EndProcedure 

Procedure itemsByShipment ()
	
	for each row in Base.Items do
		if ( row.QuantityBack = 0 ) then
			continue;
		endif; 
		newRow = Items.Add ();
		FillPropertyValues ( newRow, row );
		newRow.Picked = false;
		newRow.QuantityPlan = newRow.QuantityBack;
		newRow.QuantityPkgPlan = newRow.QuantityPkgBack;
		newRow.Quantity = 0;
		newRow.QuantityPkg = 0;
	enddo; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	if ( not canChange () ) then
		Cancel = true;
		return;
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure

Function canChange ()
	
	if ( IsInRole ( "Administrator" ) ) then
		return true;
	endif; 
	status = InformationRegisters.ShipmentStatuses.Get ( new Structure ( "Document", Ref ) ).Status;
	if ( status = Enums.ShipmentPoints.Finish ) then
		Output.ShipmentCannotBeChanged ();
		return false;
	endif; 
	return true;
	
EndFunction 

#endif