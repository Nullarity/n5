#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.LVIWriteOff.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	ItemDetails.Init ( Env );
	if ( not makeValues ( Env ) ) then
		return false;
	endif;
	ItemDetails.Save ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	sqlItemKeys ( Env );
	sqlItemsAndKeys ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.Company as Company, Constants.Currency as LocalCurrency,
	|	Document.PointInTime as Timestamp, Document.AmortizationAccount as AmortizationAccount,
	|	Document.Rate as Rate, Document.Factor as Factor, Document.Currency as Currency
	|from Document.LVIWriteOff as Document
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Document.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	list = new Structure ();
	fields = Env.Fields;
	amount = "Amount";
	if ( fields.Currency <> fields.LocalCurrency ) then
		amount = amount + " * &Rate / &Factor";
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	Env.Insert ( "AmountFields", list );

EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	Items.Account as Account, Items.Ref.Department as Department, Items.Employee.Individual as Employee
	|into Items
	|from Document.LVIWriteOff.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select distinct Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey, Items.Department, Items.Employee
	|into ItemKeys
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Account = Items.Account
	|index by Details.ItemKey
	|;
	|// ^ItemKeys
	|select ItemKeys.ItemKey as ItemKey
	|from ItemKeys as ItemKeys
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemsAndKeys ( Env )
	
	s = "
	|// ^ItemsAndKeys
	|select Items.LineNumber as LineNumber, Items.Item as Item,
	|	Items.Package as Package, Items.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.Employee as Employee,
	|	Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Details.ItemKey as ItemKey, 
	|	Items.Department as Department
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Account = Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	commitCost ( Env, cost );
	return true;

EndFunction

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	Cost = getCost ( Env, table );
	error = ( table.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, table );
		return false;
	endif; 
	return true;
	
EndFunction

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	SQL.Prepare ( Env );
	cost = Env.Q.Execute ().Unload ();
	p = new Structure ();
	p.Insert ( "FilterColumns", "Item" );
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "DecreasingColumns", "Cost" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Department, Employee" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.QuantityBalanceDr as Quantity,
	|	Items.Item as Item, Items.Department as Department, Balances.AmountBalanceDr as Cost,
	|	Items.Account as Account, Items.Employee, Items.ItemKey as ItemKey
	|from AccountingRegister.General.Balance ( &Timestamp,
	|	Account in ( select distinct Account from ItemKeys ), , 
	|	( ExtDimension1, ExtDimension2, ExtDimension3 ) in (
	|		select distinct Item, Department, Employee from ItemKeys
	|	) ) as Balances
	|	//
	|	// Items
	|	//
	|	left join ItemKeys as Items
	|	on Items.Item = Balances.ExtDimension1
	|	and Items.Department = Balances.ExtDimension2
	|	and Items.Employee = Balances.ExtDimension3
	|	and Balances.QuantityBalanceDr > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Item, QuantityBalance, Quantity, Department, Employee" );
	ref = Env.Ref;
	for each row in Items do
		item = row.Item;
		package = row.Package;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, item, package, row.Feature, row.Series, , row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		balance = row.QuantityBalance;
		outstanding = row.Quantity - balance;
		costRow.Quantity = outstanding;
		msg.Item = item;
		msg.Department = row.Department;
		msg.Employee = row.Employee;
		msg.QuantityBalance = Conversion.NumberToQuantity ( balance, package );
		msg.Quantity = Conversion.NumberToQuantity ( outstanding, package );
		Output.LVIBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), ref );
	enddo; 
		
EndProcedure 

Procedure commitCost ( Env, Table )
	
	fields = Env.Fields;
	amoritzation = fields.AmortizationAccount;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.LVIWriteOff;
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Department, Employee, Item, Capacity, Account", "Quantity, Cost" );
	for each row in Table do
		p.AccountDr = amoritzation;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Department;
		p.AccountCr = row.Account;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Department;
		p.DimCr3 = row.Employee;
		p.Amount = row.Cost;
		p.QuantityCr = row.Quantity * row.Capacity;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	
EndProcedure

#endregion

#endif