#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Function Fetch ( Day, Warehouse, Location, Method ) export

	s = "
	|select top 1 Sales.Ref as Ref
	|from Document.RetailSales as Sales
	|where Sales.Warehouse = &Warehouse
	|and Sales.Location = &Location
	|and Sales.Method = &Method
	|and Sales.Date between &DateStart and &DateEnd
	|and Sales.Posted
	|";
	q = new Query ( s );
	q.SetParameter ( "Warehouse", Warehouse );
	q.SetParameter ( "Location", Location );
	q.SetParameter ( "Method", Method );
	date = BegOfDay ( Day );
	q.SetParameter ( "DateStart", date );
	q.SetParameter ( "DateEnd", EndOfDay ( date ) );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction 
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.RetailSales.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	restoreCost = Env.RestoreCost;
	calculateCost = Env.CalculateCost;
	if ( not restoreCost ) then
		if ( recalculationRequired ( Env ) ) then
			return false;
		endif;
		makeItems ( Env );
	endif;
	prepareSales ( Env );
	ItemDetails.Init ( Env );
	if ( calculateCost ) then
		if ( not makeValues ( Env ) ) then
			return false;
		endif;
	endif;
	if ( not restoreCost
		and not Env.Realtime ) then
		SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp, Env.UnresolvedItems );
	endif;
	if ( not calculateCost ) then
		makeSales ( Env );
	endif;
	ItemDetails.Save ( Env );
	if ( not restoreCost ) then
		commitVAT ( Env );
		commitIncome ( Env );
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
	sqlItems ( Env );
	calculateCost = Env.CalculateCost;
	if ( not calculateCost ) then
		sqlSales ( Env );
	endif;
	if ( not Env.RestoreCost ) then
		sqlRecalculationRequired ( Env );
		sqlVAT ( Env );
		sqlSequence ( Env );
		sqlQuantity ( Env );
	endif; 
	if ( calculateCost ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.Department as Department, Documents.PointInTime as Timestamp, Documents.Location as Location,
	|	Documents.Method as Method, Documents.CashFlow as CashFlow, Documents.Account as Account
	|from Document.RetailSales as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	fields = Env.Fields;
	Env.Insert ( "CalculateCost", Options.CostOnline ( fields.Company ) or Env.RestoreCost );
	Env.Insert ( "CheckBalances", Shortage.Check ( fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.Price as Price, Items.DiscountRate as DiscountRate,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	Items.Account as Account, Items.Income as Income, Items.SalesCost as SalesCost, Items.VATAccount as VATAccount,
	|	Items.Total - Items.VAT as Amount, Items.VAT as VAT, Items.Total as Total, &Warehouse as Warehouse
	|into Items
	|from Document.RetailSales.Items as Items
	|where Items.Ref = &Ref
	|and Items.Base = undefined
	|index by Item, Feature, Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlSales ( Env )
	
	s = "
	|// ^Sales
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.Income as Income, Items.Quantity as Quantity,
	|	Items.Amount as Amount, Items.Total as Total, Details.ItemKey
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = &Warehouse
	|	and Details.Account = Items.Account
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
	|select Items.Item as Item, Items.Feature as Feature, Items.Package as Package, Items.Series as Series,
	|	sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|group by Items.Item, Items.Feature, Items.Package, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey, Items.Quantity as Quantity
	|into ItemKeys
	|from (
	|	select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	   Items.Package as Package, sum ( Items.Quantity ) as Quantity
	|	from Items as Items
	|	group by Items.Item, Items.Feature, Items.Series, Items.Account, Items.Package
	|) as Items
	|	//
	|	// Details
	|	//
	|	join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = &Warehouse
	|	and Details.Account = Items.Account
	|index by ItemKey
	|;
	|select max ( Cost.Period ) as Period, Keys.ItemKey as ItemKey
	|into ReturnKeys
	|from AccumulationRegister.Cost as Cost
	|	//
	|	// Return
	|	//
	|	join ItemKeys as Keys
	|	on Keys.ItemKey = Cost.ItemKey
	|	and Keys.Quantity < 0
	|where Cost.PointInTime < &Timestamp
	|and Cost.Recorder refs Document.RetailSales
	|and Cost.RecordType = value ( AccumulationRecordType.Expense )
	|and Cost.Quantity > 0
	|and Cost.Amount > 0
	|group by Keys.ItemKey
	|;
	|// ^ItemKeys
	|select ItemKeys.ItemKey as ItemKey
	|from ItemKeys as ItemKeys
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemsAndKeys ( Env )
	
	s = "
	|// #ItemsAndKeys
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Package as Package, Items.Item.Unit as Unit,
	|	Items.Feature as Feature, Items.Series as Series, Items.Account as Account, Items.Income as Income,
	|	Items.SalesCost as SalesCost, Items.QuantityPkg as Quantity, Items.Amount as Amount,
	|	Details.ItemKey as ItemKey, Items.Total as Total, Items.Capacity as Capacity, Items.Quantity < 0 as Return
	|from Items as Items
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Items.Item
	|	and Details.Package = Items.Package
	|	and Details.Feature = Items.Feature
	|	and Details.Series = Items.Series
	|	and Details.Warehouse = &Warehouse
	|	and Details.Account = Items.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Location", fields.Location );
	q.SetParameter ( "Method", fields.Method );
	day = BegOfDay ( fields.Date );
	q.SetParameter ( "DateStart", day );
	q.SetParameter ( "DateEnd", EndOfDay ( day ) );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure prepareSales ( Env )
	
	Env.Insert ( "UnresolvedItems", new Array () );
	Env.Insert ( "SalesTable", new ValueTable () );
	table = Env.SalesTable;
	table.Columns.Add ( "Income", new TypeDescription ( "ChartOfAccountsRef.General" ) );
	table.Columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	
EndProcedure

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	makeExpenses ( Env, cost );
	commitCost ( Env, cost );
	makeItemsSales ( Env, cost );
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
	
	table = Env.ItemsAndKeys.Copy ();
	Cost = getCost ( Env, table );
	error = ( table.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, table );
		if ( Env.RestoreCost
			or Env.CheckBalances ) then
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction

Function getCost ( Env, Items )
	
	sqlCost ( Env );
	SQL.Perform ( Env );
	cost = Env.SalesCost;
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
	p.Insert ( "DecreasingColumns2", "Amount, Total" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Income, SalesCost, Return" );
	CollectionsSrv.Adjust ( cost, "Cost", Metadata.AccumulationRegisters.Cost.Resources.Amount.Type );
	result = CollectionsSrv.Decrease ( cost, Items, p );
	for each row in result do
		if ( row.Return ) then
			row.Quantity = - row.Quantity;
			row.Cost = - row.Cost;
		endif;
	enddo;
	return result;
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|// #SalesCost
	|select Balances.Lot as Lot, Balances.Quantity as Quantity, Balances.Cost as Cost,
	|	ItemKeys.ItemKey as ItemKey, ItemKeys.Item as Item, ItemKeys.Feature as Feature,
	|	ItemKeys.Series as Series, ItemKeys.Account as Account
	|from (
	|	select Balances.Lot as Lot, Balances.ItemKey as ItemKey,
	|		Balances.QuantityBalance as Quantity, Balances.AmountBalance as Cost
	|	from AccumulationRegister.Cost.Balance ( &Timestamp,
	|		ItemKey in ( select ItemKey from ItemKeys where Quantity > 0 ) ) as Balances
	|	union all
	|	select &Ref, ItemKeys.ItemKey, - ItemKeys.Quantity,
	|		case - ItemKeys.Quantity
	|			when sum ( Cost.Quantity ) then sum ( Cost.Amount )
	|			else ( - ItemKeys.Quantity ) * ( sum ( Cost.Amount ) / sum ( Cost.Quantity ) )
	|		end
	|	from AccumulationRegister.Cost as Cost
	|		//
	|		// Return
	|		//
	|		join ReturnKeys as ReturnKeys
	|		on ReturnKeys.ItemKey = Cost.ItemKey
	|		and ReturnKeys.Period = Cost.Period
	|		//
	|		// ItemKeys
	|		//
	|		join ItemKeys as ItemKeys
	|		on ItemKeys.ItemKey = ReturnKeys.ItemKey
	|	group by ItemKeys.ItemKey, ItemKeys.Quantity
	|	) as Balances
	|	//
	|	// ItemKeys
	|	//
	|	left join ItemKeys as ItemKeys
	|	on ItemKeys.ItemKey = Balances.ItemKey
	|order by Balances.Lot.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	warehouse = Env.Fields.Warehouse;
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	msg = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in Items do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, warehouse, row.Account );
		endif; 
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		balance = row.QuantityBalance;
		outstanding = row.Quantity - balance;
		costRow.Quantity = outstanding;
		msg.Item = row.Item;
		msg.Warehouse = warehouse;
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

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ItemKey, SalesCost, Quantity, Cost" );
	expenses.GroupBy ( "ItemKey, SalesCost", "Quantity, Cost" );
	date = Env.Fields.Date;
	for each row in expenses do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Document = Env.Ref;
		movement.ItemKey = row.ItemKey;
		movement.Account = row.SalesCost;
		movement.AmountDr = row.Cost;
		movement.QuantityDr = row.Quantity;
	enddo;
	
EndProcedure

Procedure commitCost ( Env, Table )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif; 
	items = Table.Copy ( , "Item, Account, SalesCost, Capacity, Quantity, Cost" );
	items.GroupBy ( "Item, Account, SalesCost, Capacity", "Quantity, Cost" );
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.DimCr2 = fields.Warehouse;
	p.Recordset = Env.Registers.General;
	for each row in items do
		p.AccountCr = row.Account;
		p.Amount = row.Cost;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.AccountDr = row.SalesCost;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.ItemsRetirement ) then
			recordset.Delete ( i );
		endif; 
		i = i - 1;
	enddo; 
	
EndProcedure

Function recalculationRequired ( Env )
	
	if ( Env.Recalculation = undefined ) then
		return false;
	endif;
	Output.RetailSalesRecalculationRequired ( , , Env.Ref );
	return true;

EndFunction

Procedure makeItemsSales ( Env, Table )
	
	recordset = Env.Registers.Sales;
	date = Env.Fields.Date;
	department = Env.Fields.Department;
	sales = Env.SalesTable;
	usual = not Env.RestoreCost;
	for each row in Table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Total;
		movement.VAT = row.Total - row.Amount;
		movement.Cost = row.Cost;
		if ( usual ) then
			rowSales = sales.Add ();
			rowSales.Income = row.Income;
			rowSales.Amount = row.Amount;
		endif; 
	enddo; 
	
EndProcedure

Procedure setCostBound ( Env )
	
	if ( Env.RestoreCost ) then
		fields = Env.Fields;
		time = fields.Timestamp;
		company = fields.Company;
		for each row in Env.ItemsAndKeys do
			Sequences.Cost.SetBound ( time, new Structure ( "Company, Item", company, row.Item ) );
		enddo; 
	endif; 
	
EndProcedure

Procedure makeSales ( Env )

	table = SQL.Fetch ( Env, "$Sales" );
	recordset = Env.Registers.Sales;
	fields = Env.Fields;
	date = fields.Date;
	department = fields.Department;
	warehouse = fields.Warehouse;
	sales = Env.SalesTable;
	for each row in table do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, , row.Feature, row.Series, warehouse, row.Account );
		endif; 
		movement = recordset.Add ();
		movement.Period = date;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Total;
		movement.VAT = row.Total - row.Amount;
		if ( not Env.RestoreCost ) then
			rowSales = sales.Add ();
			rowSales.Income = row.Income;
			rowSales.Amount = row.Amount;
		endif; 
	enddo; 
	
EndProcedure

Procedure commitIncome ( Env )
	
	fields = Env.Fields;
	Env.SalesTable.GroupBy ( "Income", "Amount" );
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	p.AccountDr = fields.Account;
	if ( fields.Method = Enums.PaymentMethods.Cash ) then
		p.DimDr1 = fields.Location;
		p.DimDr2 = fields.CashFlow;
	endif;
	p.Operation = Enums.Operations.Sales;
	for each row in Env.SalesTable do
		p.AccountCr = row.Income;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo; 
	
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
		movement.Company = company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Procedure makeItems ( Env )

	table = SQL.Fetch ( Env, "$Items" );
	recordset = Env.Registers.Items;
	fields = Env.Fields;
	date = fields.Date;
	warehouse = fields.Warehouse;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function checkBalances ( Env )
	
	if ( Env.CheckBalances ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
		SQL.Perform ( Env );
		table = SQL.Fetch ( Env, "$ShortageItems" );
		if ( table.Count () > 0 ) then
			Shortage.Items ( Env, table );
			return false;
		endif; 
	else
		Env.Registers.Items.Write = true;
	endif; 
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.Sales.Write = true;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	if ( not Env.RestoreCost ) then
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
		endif; 
	endif;
	
EndProcedure

Procedure sqlRecalculationRequired ( Env )
	
	s = "
	|// @Recalculation
	|select top 1 1 as Required
	|from (
	|	select Sales.Ref as Ref
	|	from Document.Sale as Sales
	|		//
	|		// Records
	|		//
	|		join AccumulationRegister.Items as Records
	|		on Records.Recorder = Sales.Ref
	|	where Sales.Date between &DateStart and &DateEnd
	|	and Sales.Warehouse = &Warehouse
	|	and Sales.Location = &Location
	|	and Sales.Method = &Method
	|) as Sales
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlVAT ( Env )
	
	s = "
	|// #VAT
	|select Items.VATAccount as Account, sum ( Items.VAT ) as Amount
	|from Items as Items
	|group by Items.VATAccount
	|having sum ( Items.VAT ) <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure commitVAT ( Env )
	
	table = Env.VAT;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Recordset = Env.Registers.General;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountDr = fields.Account;
	if ( fields.Method = Enums.PaymentMethods.Cash ) then
		p.DimDr1 = fields.Location;
		p.DimDr2 = fields.CashFlow;
	endif;
	p.Operation = Enums.Operations.VATPayable;
	for each row in table do
		p.AccountCr = row.Account;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure
 
#endregion

#endif