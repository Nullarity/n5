
Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		makeItems ( Env );
		makeAssets ( Env );
		commitInProgress ( Env );
	endif;
	ItemDetails.Init ( Env );
	if ( Env.RestoreCost
		or Env.CostOnline ) then
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

	setContext ( Env );
	sqlFields ( Env );
	getFields ( Env );
	sqlItems ( Env );
	sqlInProgress ( Env );
	if ( not Env.RestoreCost ) then
		sqlSequence ( Env );
		sqlQuantity ( Env );
		sqlAssets ( Env );
	endif;
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( Env.Fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.Commissioning" ) ) then
		Env.Insert ( "FixedAssets", true );
	else
		Env.Insert ( "FixedAssets", false );
	endif; 
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.PointInTime as Timestamp, Documents.Department as Department, Documents.Employee as Employee
	|from Document." +  Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	tangible = Env.FixedAssets;
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, &Warehouse as Warehouse, Items.Account as Account,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package
	|";
	if ( tangible ) then
		s = s + ",
		|	Items.FixedAsset as Asset, Items.FixedAsset.Account as AssetAccount,
		|	Items.LiquidationValue as LiquidationValue, Items.Schedule as Schedule
		|";
	else
		s = s + ",
		|	Items.IntangibleAsset as Asset, Items.IntangibleAsset.Account as AssetAccount
		|";
	endif; 
	s = s + ",
	|	Items.Method as Method, Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Expenses as Expenses,
	|	Items.Starting as Starting, Items.UsefulLife as UsefulLife,
	|	&Department as Department, &Employee as Employee
	|into Items
	|from Document." + Env.Document + ".Items as Items
	|where Items.Ref = &Ref
	|and not Items.Posted
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlInProgress ( Env )
	
	tangible = Env.FixedAssets;
	s = "
	|select Items.Item as Item, Items.Amount as Amount,
	|	Items.Account as Account
	|";
	if ( tangible ) then
		s = s + ",
		|	Items.FixedAsset as Asset, Items.FixedAsset.Account as AssetAccount,
		|	Items.LiquidationValue as LiquidationValue, Items.Schedule as Schedule
		|";
	else
		s = s + ",
		|	Items.IntangibleAsset as Asset, Items.IntangibleAsset.Account as AssetAccount
		|";
	endif; 
	s = s + ",
	|	Items.Method as Method, Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Expenses as Expenses,
	|	Items.Starting as Starting, Items.UsefulLife as UsefulLife,
	|	&Department as Department, &Employee as Employee
	|into InProgress
	|from Document." + Env.Document + ".InProgress as Items
	|where Items.Ref = &Ref
	|;
	|// #InProgress
	|select *
	|from InProgress
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
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Package as Package, Items.Series as Series, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|group by Items.Warehouse, Items.Item, Items.Feature, Items.Package, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItemKeys ( Env )
	
	s = "
	|select distinct Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey
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
	|	Items.Account as Account, Items.AssetAccount as AssetAccount,
	|	Items.Asset as Asset, Items.QuantityPkg as Quantity, Items.Capacity as Capacity,
	|	Details.ItemKey as ItemKey
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

Procedure sqlAssets ( Env )
	
	tangible = Env.FixedAssets;
	s = "
	|// ^Assets
	|select Items.Asset as Asset, Items.Department as Department, Items.Employee as Employee, 
	|	Items.Acceleration as Acceleration, Items.Charge as Charge, Items.Expenses as Expenses,
	|	Items.Method as Method, Items.Starting as Starting, Items.UsefulLife as UsefulLife
	|";
	if ( tangible ) then
		s = s + ",
		|Items.LiquidationValue as LiquidationValue, Items.Schedule as Schedule";
	endif; 
	s = s + "
	|from Items as Items
	|union all
	|select Items.Asset, Items.Department, Items.Employee, 
	|	Items.Acceleration, Items.Charge, Items.Expenses,
	|	Items.Method, Items.Starting, Items.UsefulLife
	|";
	if ( tangible ) then
		s = s + ",
		|Items.LiquidationValue, Items.Schedule";
	endif; 
	s = s + "
	|from InProgress as Items
	|where Items.Asset not in ( select Asset from Items )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Department", fields.Department );
	q.SetParameter ( "Employee", fields.Employee );
	SQL.Perform ( Env );
	
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

Procedure commitInProgress ( Env )
	
	fields = Env.Fields;
	date = fields.Date;
	company = fields.Company;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.Recordset = Env.Registers.General;
	for each row in Env.InProgress do
		p.Amount = row.Amount;
		p.AccountCr = row.Account;
		p.DimCr1 = row.Item;
		p.AccountDr = row.AssetAccount;
		p.DimDr1 = row.Asset;
		p.QuantityDr = 1;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure makeAssets ( Env )
	
	table = SQL.Fetch ( Env, "$Assets" );
	makeDepreciation ( Env, table );
	makeLocation ( Env, table );
	makeCommissioning ( Env, table );
	
EndProcedure

Procedure makeDepreciation ( Env, Assets )
	
	tangible = Env.FixedAssets;
	if ( tangible ) then
		recordset = Env.Registers.Depreciation;
	else
		recordset = Env.Registers.Amortization;
	endif; 
	date = Env.Fields.Date;
	for each row in Assets do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Asset = row.Asset;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.UsefulLife = row.UsefulLife;
		if ( tangible ) then
			movement.LiquidationValue = row.LiquidationValue;
			movement.Schedule = row.Schedule;
		endif; 
	enddo; 
	
EndProcedure

Procedure makeLocation ( Env, Assets )
	
	tangible = Env.FixedAssets;
	if ( tangible ) then
		recordset = Env.Registers.FixedAssetsLocation;
	else
		recordset = Env.Registers.IntangibleAssetsLocation;
	endif;
	date = Env.Fields.Date;
	for each row in Assets do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Asset = row.Asset;
		movement.Department = row.Department;
		movement.Employee = row.Employee;
	enddo; 
	
EndProcedure

Procedure makeCommissioning ( Env, Assets )
	
	tangible = Env.FixedAssets;
	if ( tangible ) then
		recordset = Env.Registers.Commissioning;
	else
		recordset = Env.Registers.IntangibleAssetsCommissioning;
	endif;
	date = Env.Fields.Date;
	for each row in Assets do
		movement = recordset.Add ();
		movement.Asset = row.Asset;
		movement.Date = date;
	enddo; 
	
EndProcedure

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	commitCost ( Env, cost );
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
		if ( Env.RestoreCost
			or Env.CheckBalances ) then
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
	p.Insert ( "AddInTable1FromTable2", "Capacity, Warehouse, Account, Asset, AssetAccount" );
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
		msg.Item = row.Item;
		msg.Warehouse = row.Warehouse;
		msg.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Package );
		msg.Quantity = Conversion.NumberToQuantity ( row.Quantity - row.QuantityBalance, row.Package );
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

Procedure commitCost ( Env, Table )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif; 
	fields = Env.Fields;
	date = fields.Date;
	company = fields.Company;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Warehouse, Item, Capacity, Account, Asset, AssetAccount", "Quantity, Cost" );
	for each row in Table do
		p.Amount = row.Cost;
		p.AccountCr = row.Account;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Warehouse;
		p.AccountDr = row.AssetAccount;
		p.DimDr1 = row.Asset;
		p.QuantityDr = 1;
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
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.General.Write = true;
	if ( not Env.RestoreCost ) then
		if ( Env.FixedAssets ) then
			registers.Depreciation.Write = true;
			registers.FixedAssetsLocation.Write = true;
			registers.Commissioning.Write = true;
		else
			registers.Amortization.Write = true;
			registers.IntangibleAssetsLocation.Write = true;
			registers.IntangibleAssetsCommissioning.Write = true;
		endif; 
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
		endif; 
	endif;
	
EndProcedure
