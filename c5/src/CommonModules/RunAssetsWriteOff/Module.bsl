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

	setContext ( Env );
	sqlFields ( Env );
	getFields ( Env );
	sqlItems ( Env );
	sqlItemsTable ( Env );
	getTables ( Env );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.AssetsWriteOff" ) ) then
		Env.Insert ( "FixedAssets", true );
	else
		Env.Insert ( "FixedAssets", false );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company,
	|	Documents.PointInTime as Timestamp, Documents.Product as Product,
	|	Documents.ProductFeature as ProductFeature, Documents.ExpenseAccount as ExpenseAccount,
	|	Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	tangible = Env.FixedAssets;
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Item.Unit.Code as Unit,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &ExpenseAccount else Items.ExpenseAccount end as ExpenseAccount,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim1 else Items.Dim1 end as Dim1,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim2 else Items.Dim2 end as Dim2,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim3 else Items.Dim3 end as Dim3,
	|	case when ( Items.Product = value ( Catalog.Items.EmptyRef ) ) then &Product else Items.Product end as Product,
	|	case when ( Items.ProductFeature = value ( Catalog.Features.EmptyRef ) ) then &ProductFeature else Items.ProductFeature end as ProductFeature,
	|	Items.Item.Account as Account";
	if ( tangible ) then
		s = s + ", Items.Item.DepreciationAccount";
	else
		s = s + ", Items.Item.AmortizationAccount";
	endif;
	s = s + " as DepreciationAccount
	|into Items
	|from Document." + Env.Document + ".Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemsTable ( Env )
	
	s = "
	|// ^Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, 1 as Quantity, Items.Unit as Unit,
	|	Items.ExpenseAccount as ExpenseAccount, Items.Dim1 as Dim1, Items.Dim2 as Dim2, Items.Dim3 as Dim3,
	|	Items.Product as Product, Items.ProductFeature as ProductFeature,
	|	Items.Account as Account, Items.DepreciationAccount as DepreciationAccount
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Company", fields.Company );
	q.SetParameter ( "Product", fields.Product );
	q.SetParameter ( "ProductFeature", fields.ProductFeature );
	q.SetParameter ( "ExpenseAccount", fields.ExpenseAccount );
	q.SetParameter ( "Dim1", fields.Dim1 );
	q.SetParameter ( "Dim2", fields.Dim2 );
	q.SetParameter ( "Dim3", fields.Dim3 );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeExpenses ( Env, cost );
	commitCost ( Env, cost );
	return true;

EndFunction

Procedure lockCost ( Env )
	
	table = SQL.Fetch ( Env, "$Items" );
	if ( table.Count () > 0 ) then
		lock = new DataLock ();
		item = lock.Add ( "AccountingRegister.General");
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "Account", "Account" );
		item.UseFromDataSource ( "ExtDimension1", "Item" );
		item = lock.Add ( "AccountingRegister.General");
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = table;
		item.UseFromDataSource ( "Account", "DepreciationAccount" );
		item.UseFromDataSource ( "ExtDimension1", "Item" );
		lock.Lock ();
	endif;
	
EndProcedure

Function calcCost ( Env, Cost )
	
	table = SQL.Fetch ( Env, "$Items" );
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
	p.Insert ( "DecreasingColumns", "Cost, Depreciation" );
	p.Insert ( "AddInTable1FromTable2", "Product, ProductFeature, ExpenseAccount, Dim1, Dim2, Dim3" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction 

Procedure sqlCost ( Env )
	
	s = "
	|select Balances.Item as Item, Balances.Account as Account, 
	|	Balances.DepreciationAccount as DepreciationAccount, sum ( Balances.Cost ) as Cost, 
	|	sum ( Balances.Depreciation ) as Depreciation, sum ( Balances.QuantityBalance ) as Quantity
	|from (
	|	//
	|	// Cost
	|	//
	|	select Balances.AmountBalance as Cost, Items.Item as Item, 1 as QuantityBalance, 
	|		Items.Account as Account, 0 as Depreciation,  
	|		Items.DepreciationAccount as DepreciationAccount
	|	from AccountingRegister.General.Balance ( &Timestamp, Account in ( select Account from Items ), , 
	|											ExtDimension1 in ( select Item from Items ) and Company = &Company ) as Balances
	|		//
	|		// Items
	|		//
	|		left join Items as Items
	|		on Items.Account = Balances.Account 
	|		and Items.Item = Balances.ExtDimension1
	|	//
	|	// Depreciation
	|	//
	|	union all
	|	select 0 as Cost, Items.Item as Item, 0 as QuantityBalance, Items.Account as Account,  
	|		Balances.AmountBalanceCr as Depreciation, Items.DepreciationAccount as DepreciationAccount
	|	from AccountingRegister.General.Balance ( &Timestamp, Account in ( select DepreciationAccount from Items ), , 
	|											ExtDimension1 in ( select Item from Items ) and Company = &Company ) as Balances
	|		//
	|		// Items
	|		//
	|		left join Items as Items
	|		on Items.Account = Balances.Account 
	|		and Items.Item = Balances.ExtDimension1
	|	) as Balances
	|group by Balances.Item, Balances.Account, Balances.DepreciationAccount
	|having sum ( Balances.QuantityBalance ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure completeCost ( Env, Cost, Items )
	
	column = "Item";
	msg = Posting.Msg ( Env, "Item" );
	for each row in Items do
		costRow = Cost.Add ();
		FillPropertyValues ( costRow, row );
		msg.Item = row.Item;
		Output.AssetBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo; 
		
EndProcedure 

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature, Cost, Depreciation" );
	expenses.GroupBy ( "ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature", "Cost, Depreciation" );
	date = Env.Fields.Date;
	expensesType = Type ( "CatalogRef.Expenses" );
	departmentsType = Type ( "CatalogRef.Departments" );
	for each row in expenses do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Document = Env.Ref;
		movement.ItemKey = Catalogs.ItemKeys.EmptyRef ();
		movement.Account = row.ExpenseAccount;
		movement.Expense = findDimension ( row, expensesType );
		movement.Department = findDimension ( row, departmentsType );
		movement.Product = row.Product;
		movement.ProductFeature = row.ProductFeature;
		movement.AmountDr = row.Cost - row.Depreciation;
	enddo;
	
EndProcedure

Function findDimension ( Row, Type )
	
	value = Row.Dim1;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Row.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	value = Row.Dim2;
	if ( TypeOf ( value ) = Type ) then
		return value;
	endif;
	
EndFunction 

Procedure commitCost ( Env, Table )
	
	cleanCost ( Env );
	fields = Env.Fields;
	date = fields.Date;
	company = fields.Company;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Item, Account, DepreciationAccount, Dim1, Dim2, Dim3, ExpenseAccount", "Depreciation, Cost" );
	for each row in Table do
		if ( row.Depreciation > 0 ) then
			p.Amount = row.Depreciation;
			p.AccountCr = row.Account;
			p.DimCr1 = row.Item;
			p.AccountDr = row.DepreciationAccount;
			p.DimDr1 = row.Item;
			GeneralRecords.Add ( p );
		endif;
		p.Amount = row.Cost - row.Depreciation;
		p.AccountCr = row.Account;
		p.QuantityCr = 1;
		p.DimCr1 = row.Item;
		p.AccountDr = row.ExpenseAccount;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
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

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	
EndProcedure
