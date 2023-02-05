#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	Fields.Add ( "Number" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.Startup.Synonym + " #" + Data.Number + " " + Format ( Data.Date, "DLF=D" );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		makeItems ( Env );
	endif;
	ItemDetails.Init ( Env );
	if ( not Env.RestoreCost ) then
		if ( not makeValues ( Env ) ) then
			return false;
		endif;
	endif;
	if ( not Env.RestoreCost
		and not Env.Realtime ) then
		SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	endif;
	ItemDetails.Save ( Env );
	if ( not Env.RestoreCost ) then
		attachSequence ( Env );
		if ( not checkBalances ( Env ) ) then
			return false;
		endif; 
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	if ( not Env.RestoreCost ) then
		sqlSequence ( Env );
		sqlQuantity ( Env );
	endif; 
	if ( not Env.RestoreCost ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( Env.Fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Document.Date as Date, Document.Warehouse as Warehouse, Document.Company as Company, Constants.Currency as LocalCurrency,
	|	Document.PointInTime as Timestamp, Document.CostLimit as CostLimit, Document.AmortizationAccount as AmortizationAccount,
	|	Document.ExploitationAccount as ExploitationAccount, Document.Rate as Rate, Document.Factor as Factor, Document.Currency as Currency
	|from Document.Startup as Document
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
	residual = "ResidualValue";
	if ( fields.Currency <> fields.LocalCurrency ) then
		residual = residual + " * &Rate / &Factor";
	endif;
	list.Insert ( "ResidualValue", "cast ( " + residual + " as Number ( 15, 2 ) )" );
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
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	Items.RowKey as RowKey, " + Env.AmountFields.ResidualValue + " as ResidualValue,
	|	Items.ExpenseAccount as ExpenseAccount, Items.Expense as Expense, Items.Product as Product,	Items.ProductFeature as ProductFeature,
	|	Items.Account as Account, Items.KeepOnBalance as KeepOnBalance, Items.Department as Department, Items.Employee as Employee
	|into Items
	|from Document.Startup.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlSequence ( Env )
	
	s = "
	|// ^SequenceCost
	|select distinct Items.Item as Item
	|from Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlQuantity ( Env )
	
	s = "
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Package as Package, sum ( Items.QuantityPkg ) as Quantity, Items.RowKey as RowKey
	|from Items as Items
	|group by Items.Warehouse, Items.Item, Items.Feature, Items.Series, Items.Package, Items.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select distinct Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey, Items.RowKey as RowKey
	|into ItemKeys
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = Items.Warehouse
	|	and Details.Account = Items.Account
	|group by Items.Item, Details.ItemKey, Items.RowKey, Items.Feature, Items.Account, Items.Series
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
	|select Items.LineNumber as LineNumber, Items.Warehouse as Warehouse, Items.Item as Item,
	|	Items.Package as Package, Items.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.ExpenseAccount as ExpenseAccount,
	|	Items.Product as Product, Items.ProductFeature as ProductFeature, Items.Employee.Individual as Employee,
	|	Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Details.ItemKey as ItemKey, Items.RowKey as RowKey, 
	|	Items.KeepOnBalance as KeepOnBalance, Items.ResidualValue as ResidualValue, Items.Department as Department, Items.Expense as Expense
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = Items.Warehouse
	|	and Details.Account = Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	makeMovements ( Env, cost );
	setCostBound ( Env );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	table = SQL.Fetch ( Env, "$ItemKeys" );
	if ( table.Count () > 0 ) then
		lock = new DataLock ();
		item = lock.Add ( "AccumulationRegister.Cost");
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "ItemKey", "ItemKey" );
		lock.Lock ();
	endif;
	
EndProcedure

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	Cost = getCost ( Env, table );
	error = ( table.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, table );
		if ( not Env.RestoreCost ) then
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	SQL.Prepare ( Env );
	cost = Env.Q.Execute ().Unload ();
	p = new Structure ();
	p.Insert ( "FilterColumns", "ItemKey" );
	if ( Options.Features () ) then
		p.FilterColumns = p.FilterColumns + ", Feature";
	endif; 
	if ( Options.Series () ) then
		p.FilterColumns = p.FilterColumns + ", Series";
	endif; 
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "DecreasingColumns", "Cost" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Warehouse, Product, ProductFeature, ExpenseAccount, KeepOnBalance, RowKey, ResidualValue, Department, Employee, Expense" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.Lot as Lot, Balances.QuantityBalance as Quantity,
	|	Balances.AmountBalance as Cost, ItemKeys.ItemKey as ItemKey, ItemKeys.Item as Item,
	|	ItemKeys.Feature as Feature, ItemKeys.Series as Series, ItemKeys.Account as Account
	|from AccumulationRegister.Cost.Balance ( &Timestamp, ItemKey in ( select ItemKey from ItemKeys ) ) as Balances
	|	//
	|	// ItemKeys
	|	//
	|	left join ItemKeys as ItemKeys
	|	on ItemKeys.ItemKey = Balances.ItemKey
	|	and Balances.QuantityBalance > 0
	|order by Balances.Lot.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in Items do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		balance = row.QuantityBalance;
		outstanding = row.Quantity - balance;
		costRow.Quantity = outstanding;
		msg.Item = row.Item;
		msg.Warehouse = row.Warehouse;
		msg.QuantityBalance = Conversion.NumberToQuantity ( balance, row.Unit );
		msg.Quantity = Conversion.NumberToQuantity ( outstanding, row.Unit );
		Output.ItemsCostBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo; 
		
EndProcedure 

Procedure makeCost ( Env, Table )
	
	recordset = Env.Registers.Cost;
	date = Env.Fields.Date;
	for each row in Table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.ItemKey = row.ItemKey;
		movement.Lot = row.Lot;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
	enddo; 
	
EndProcedure

Procedure makeMovements ( Env, Table ) 

	fields = Env.Fields;
	Env.Insert ( "Features", Options.Features () );
	Env.Insert ( "Details" );
	Env.Insert ( "Price" );
	Env.Insert ( "CostLimit", Currencies.Convert ( fields.CostLimit, fields.Currency, fields.LocalCurrency,
		fields.Date, fields.Rate, fields.Factor ) );
	Env.Insert ( "FullDepreciation" );
	for each row in Table do
		if ( row.Cost = undefined ) then
			row.Cost = 0;
		endif;
		Env.Price = row.Cost / ? ( row.Quantity > 0, row.Quantity, 1 );
		curResidualValue = Min ( Env.Price, row.ResidualValue ) * row.Quantity;
		fillDetails ( Env, Row );
		fullDepreciation = Env.Price <= Env.CostLimit;
		if ( not fullDepreciation ) then
			if ( Env.CostLimit <> 0 ) then
				if ( curResidualValue <> 0 ) then
					residualIgnored ( Env, row );
					curResidualValue = 0;
				endif;			
			elsif ( Env.Price < row.ResidualValue ) then
				priceLess ( Env, row );
			endif;
		endif;
		commitTransfer ( Env, row );
		if ( Row.Cost = 0 ) then
			continue;
		endif;
		depreciationAmount = Row.Cost - curResidualValue;
		makeDepreciation ( Env, Row, depreciationAmount );
		if ( fullDepreciation ) then
			finishExploitation ( Env, Row, depreciationAmount );
		endif;
	enddo;

EndProcedure

Procedure fillDetails ( Env, Row )

	d = ", ";
	if ( Env.Features ) then
		if ( not row.Feature.IsEmpty () ) then
			d = d + row.Feature + ", ";
		endif;	
	endif;  
	d = Left ( d, StrLen ( d ) - 2 );
	Env.Details = d;

EndProcedure

Procedure residualIgnored ( Env, Row )
	
	p = new Structure ( "Item, Details, CostLimit, Price, ResidualValue",
	Row.Item, Env.Details, Env.CostLimit, Env.Price, Row.ResidualValue );
	Output.ResidualValueIgnored ( p );

EndProcedure

Procedure priceLess ( Env, Row )

	p = new Structure ( "Item, Details, Price, ResidualValue", Row.Item, Env.Details, Env.Price, Row.ResidualValue );
	Output.PriceIsLessThenResidualValue ( p );

EndProcedure

Procedure commitTransfer ( Env, Row ) 

	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif;
	p = GeneralRecords.GetParams ();
	p.Date = Env.Fields.Date;
	p.Company = Env.Fields.Company;
	p.Operation = Enums.Operations.LVIExploitation;
	p.Recordset = Env.Registers.General;
	p.AccountCr = Row.Account;
	p.AccountDr = Env.Fields.ExploitationAccount;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.DimDr1Type = "Items";
	p.DimDr2Type = "Departments";
	p.DimDr3Type = "Employees";
	p.Amount = Row.Cost;
	p.QuantityCr = Row.Quantity;
	p.QuantityDr = Row.Quantity;
	p.DimCr1 = Row.Item;
	p.DimCr2 = Row.Warehouse;
	p.DimDr1 = Row.Item;
	p.DimDr2 = Row.Department;
	p.DimDr3 = Row.Employee;
	GeneralRecords.Add ( p );

EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		operation = recordset [ i ].Operation;
		if ( operation = Env.Locals.exploitation ) or ( operation = Env.Locals.writeOff ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Procedure makeDepreciation ( Env, Row, Amount ) 

	makeExpenses ( Env, Row, Amount );
	if ( Amount <> 0 ) then
		commitExpenses ( Env, row, Amount );
	endif;

EndProcedure

Procedure makeExpenses ( Env, Row, Amount ) 

	movement = Env.Registers.Expenses.Add ();
	movement.Period = Env.Fields.Date;
	movement.Document = Env.Ref;
	movement.ItemKey = Row.ItemKey;
	movement.Account = Row.ExpenseAccount;
	movement.Product = Row.Product;
	movement.ProductFeature = Row.ProductFeature;
	movement.AmountDr = Amount;
	movement.QuantityDr = Row.Quantity;
	movement.Expense = Row.Expense;
	movement.Department = Row.Department;

EndProcedure

Procedure commitExpenses ( Env, Row, Amount ) 

	if ( Amount = 0 ) then
		return;
	endif;
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif;
	p = GeneralRecords.GetParams ();
	p.Date = Env.Fields.Date;
	p.Company = Env.Fields.Company;
	p.Recordset = Env.Registers.General;
	p.AccountDr = Row.ExpenseAccount;
	p.DimDr1 = Row.Expense;
	department = Row.Department;
	p.DimDr2 = department;
	p.DimCr1 = Row.Item;
	p.Amount = Amount;
	p.Operation = Enums.Operations.LVIExploitation;
	p.AccountCr = Env.Fields.AmortizationAccount;
	p.DimCr2Type = "Departments";
	p.DimCr2 = department;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure finishExploitation ( Env, Row, Amount ) 

	if ( Amount = 0 ) then
		return;
	endif;
	p = GeneralRecords.GetParams ();
	p.Date = Env.Fields.Date;
	p.Company = Env.Fields.Company;
	p.Recordset = Env.Registers.General;
	p.AccountDr = Env.Fields.AmortizationAccount;
	p.DimDr1 = Row.Item;
	p.DimDr2 = Row.Department;
	p.AccountCr = Env.Fields.ExploitationAccount;
	p.DimCr1 = Row.Item;
	p.DimCr2 = Row.Department;
	p.DimCr3 = Row.Employee;
	p.Amount = Amount;
	p.Operation = Enums.Operations.LVIWriteOff;
	if ( not Row.KeepOnBalance ) then
		p.QuantityCr = Row.Quantity;
	endif;
	GeneralRecords.Add ( p );
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		table = SQL.Fetch ( Env, "$ItemsAndKeys" );
		fields = Env.Fields;
		time = fields.Timestamp;
		company = fields.Company;
		for each row in table do
			Sequences.Cost.SetBound ( time, new Structure ( "Company, Item", company, row.Item ) );
		enddo; 
	endif; 
	
EndProcedure

Procedure attachSequence ( Env )

	recordset = Sequences.Cost.CreateRecordSet ();
	//@skip-warning
	recordset.Filter.Recorder.Set ( Env.Ref );
	table = SQL.Fetch ( Env, "$SequenceCost" );
	fields = Env.Fields;
	date = fields.Date;
	company = fields.Company;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Company= company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Procedure makeItems ( Env )

	table = SQL.Fetch ( Env, "$Items" );
	recordset = Env.Registers.Items;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function checkBalances ( Env )
	
	if ( Env.CheckBalances ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
	else
		Env.Registers.Items.Write = true;
	endif; 
	if ( Env.Selection.Count () = 0 ) then
		return true;
	endif;
	SQL.Perform ( Env );
	if ( not Env.CheckBalances ) then
		return true;
	endif; 
	table = SQL.Fetch ( Env, "$ShortageItems" );
	if ( table.Count () > 0 ) then
		Shortage.Items ( Env, table );
		return false;
	endif; 
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	Env.Registers.Cost.Write = true;
	Env.Registers.General.Write = true;
	Env.Registers.Expenses.Write = true;
	if ( not Env.RestoreCost ) then
		if ( not Env.CheckBalances ) then
			Env.Registers.Items.Write = true;
		endif; 
	endif;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	header ( Params, Env );
	table ( Params, Env );
	footer ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	tabDoc.PerPage = 1;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	SetPrivilegedMode ( true );
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as Number, Document.Date as Date,
	|	Document.Company.FullDescription as Company, Document.Warehouse as Warehouse, Document.Currency as Currency 
	|from Document.Startup as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item as Item, Items.QuantityPkg as Quantity, Items.Price as Price, Items.Amount as Amount,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit
	|from Document.Startup.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure header ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	fields = Env.Fields;
	p = area.Parameters;
	p.Fill ( fields );
	p.Date = Format ( fields.Date, "DLF=D" );
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure table ( Params, Env )
	
	area = Env.T.GetArea ( "Row" );
	table = Env.Items;
	tabDoc = Params.TabDoc;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	line = 0;
	for each row in table do
		p.Fill ( row );
		line = line + 1;
		p.Line = line;
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo;
	Env.Insert ( "AmountTotal", table.Total ( "Amount" ) );
	Env.Insert ( "QuantityTotal", table.Total ( "Quantity" ) );
	
EndProcedure

Procedure footer ( Params, Env )
	
	area = Env.T.GetArea ( "Footer" );
	tabDoc = Params.TabDoc;
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Quantity = Env.QuantityTotal;
	p.Amount = Env.AmountTotal;
	p.AmountWords = Conversion.AmountToWords ( p.Amount, , CurrentLanguage ().LanguageCode );
	tabDoc.Put ( area );        
	
EndProcedure

#endregion

#endif