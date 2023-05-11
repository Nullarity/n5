#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.WriteOff.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		if ( fields.Forms
			and not RunRanges.Check ( Env ) ) then
			return false;
		endif;
		makeItems ( Env );
		if ( Env.DocumentOrderExists
			and not makeReserves ( Env ) ) then
			return false;
		endif;
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
		if ( fields.ApplyVAT ) then
			commitVAT ( Env );
		endif;
		if ( fields.Forms ) then
			if ( not makeRanges ( Env ) ) then
				return false;
			endif;
		endif;
		if ( fields.FuelExpense ) then
			makeFuelToExpense ( Env );
		endif;
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
	setContext ( Env );
	sqlItems ( Env );
	fields = Env.Fields;
	if ( fields.Forms ) then
		RunRanges.SqlData ( Env );
	endif;
	if ( not Env.RestoreCost ) then
		sqlSequence ( Env );
		if ( Env.DocumentOrderExists ) then
			sqlReserves ( Env );
		endif;
		if ( fields.ApplyVAT ) then
			sqlVAT ( Env );
		endif;
		sqlQuantity ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	Env.Insert ( "CheckBalances", Shortage.Check ( fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.PointInTime as Timestamp, Documents.Product as Product, Documents.VATUse > 0 as ApplyVAT,
	|	Documents.ProductFeature as ProductFeature, Documents.ExpenseAccount as ExpenseAccount,
	|	Documents.Dim1 as Dim1, Documents.Dim2 as Dim2, Documents.Dim3 as Dim3, Documents.VATAccount as VATAccount,
	|	Documents.VATDim1 as VATDim1, Documents.VATDim2 as VATDim2, Documents.VATDim3 as VATDim3,
	|	isnull ( Forms.Exists, false ) as Forms, Documents.Base refs Document.Waybill as FuelExpense,
	|	Cars.Ref as Car
	|from Document.WriteOff as Documents
	|	//
	|	// Forms
	|	//
	|	left join (
	|		select top 1 true as Exists
	|		from Document.WriteOff.Items as Items
	|		where Items.Item.Form
	|		and Items.Ref = &Ref ) as Forms
	|	on true
	|	//
	|	// Cars
	|	//
	|	left join Catalog.Cars as Cars
	|	on Cars.Warehouse = Documents.Warehouse
	|where Documents.Ref = &Ref
	|;
	|// @DocumentOrderExists
	|select top 1 true as Exist
	|from Document.WriteOff.Items as Items
	|where Items.DocumentOrder <> undefined
	|and Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure setContext ( Env )
	
	Env.Insert ( "DocumentOrderExists", Env.DocumentOrderExists <> undefined and Env.DocumentOrderExists.Exist );

EndProcedure

Procedure sqlItems ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.RowKey as RowKey, Items.DocumentOrder as DocumentOrder,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &ExpenseAccount else Items.ExpenseAccount end as ExpenseAccount,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim1 else Items.Dim1 end as Dim1,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim2 else Items.Dim2 end as Dim2,
	|	case when ( Items.ExpenseAccount = value ( ChartOfAccounts.General.EmptyRef ) ) then &Dim3 else Items.Dim3 end as Dim3,
	|	case when ( Items.Product = value ( Catalog.Items.EmptyRef ) ) then &Product else Items.Product end as Product,
	|	case when ( Items.ProductFeature = value ( Catalog.Features.EmptyRef ) ) then &ProductFeature else Items.ProductFeature end as ProductFeature,
	|	Items.Account as Account, Items.Range as Range
	|into Items
	|from Document.WriteOff.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlVAT ( Env )
	
	s = "
	|// #VAT
	|select Items.VATAccount as Account,
	|	sum (
	|		case Items.Ref.Currency when Constants.Currency then Items.VAT
	|		else Items.VAT * Items.Ref.Rate / Items.Ref.Factor
	|		end
	|	) as Amount
	|from Document.WriteOff.Items as Items
	|	//
	|	// Contstants
	|	//
	|	left join Constants as Constants
	|	on true
	|where Items.Ref = &Ref
	|and Items.VAT <> 0
	|group by Items.VATAccount
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

Procedure sqlReserves ( Env )
	
	s = "
	|select Items.RowKey as RowKey, Items.Warehouse as Warehouse, Items.Item as Item,
	|	Items.Feature as Feature, Items.LineNumber as LineNumber, Items.Quantity as Quantity,
	|	Items.DocumentOrder as DocumentOrder, case when SalesOrders.Item is null then true else false end as Invalid
	|into Reserves
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	left join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.DocumentOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Item = Items.Item
	|	and SalesOrders.Feature = Items.Feature
	|	and SalesOrders.Reservation <> value ( Enum.Reservation.None )
	|where Items.DocumentOrder refs Document.SalesOrder
	|union all
	|select Items.RowKey, Items.Warehouse, Items.Item, Items.Feature, Items.LineNumber,
	|	Items.Quantity, Items.DocumentOrder, case when InternalOrders.Item is null then true else false end
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	left join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.Ref = Items.DocumentOrder
	|	and InternalOrders.RowKey = Items.RowKey
	|	and InternalOrders.Reservation <> value ( Enum.Reservation.None )
	|where Items.DocumentOrder refs Document.InternalOrder
	|index by Items.RowKey
	|;
	|// ^Reserves
	|select Reserves.Warehouse as Warehouse, Reserves.RowKey as RowKey,
	|	Reserves.Quantity as Quantity, Reserves.DocumentOrder as DocumentOrder,
	|	Reserves.LineNumber as LineNumber, Reserves.Invalid as Invalid
	|from Reserves as Reserves
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlQuantity ( Env )
	
	s = "
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Package as Package, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|";
	if ( Env.DocumentOrderExists ) then
		s = s + "
		|where Items.RowKey not in ( select RowKey from Reserves )";
	endif;
	s = s + "
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
	|	Items.Account as Account, Items.ExpenseAccount as ExpenseAccount,
	|	Items.Dim1 as Dim1, Items.Dim2 as Dim2, Items.Dim3 as Dim3,
	|	Items.Product as Product, Items.ProductFeature as ProductFeature,
	|	Items.QuantityPkg as Quantity, Items.Capacity as Capacity, Details.ItemKey as ItemKey
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
	|// :order by Items.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Product", fields.Product );
	q.SetParameter ( "ProductFeature", fields.ProductFeature );
	q.SetParameter ( "ExpenseAccount", fields.ExpenseAccount );
	q.SetParameter ( "Dim1", fields.Dim1 );
	q.SetParameter ( "Dim2", fields.Dim2 );
	q.SetParameter ( "Dim3", fields.Dim3 );
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

Function makeValues ( Env )

	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	makeExpenses ( Env, cost );
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
	p.Insert ( "AddInTable1FromTable2", "Capacity, Warehouse, Product, ProductFeature, ExpenseAccount, Dim1, Dim2, Dim3" );
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

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ItemKey, ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature, Quantity, Cost" );
	expenses.GroupBy ( "ItemKey, ExpenseAccount, Dim1, Dim2, Dim3, Product, ProductFeature", "Quantity, Cost" );
	date = Env.Fields.Date;
	expensesType = Type ( "CatalogRef.Expenses" );
	departmentsType = Type ( "CatalogRef.Departments" );
	for each row in expenses do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Document = Env.Ref;
		movement.ItemKey = row.ItemKey;
		movement.Account = row.ExpenseAccount;
		movement.Expense = findDimension ( row, expensesType );
		movement.Department = findDimension ( row, departmentsType );
		movement.Product = row.Product;
		movement.ProductFeature = row.ProductFeature;
		movement.AmountDr = row.Cost;
		movement.QuantityDr = row.Quantity;
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
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	Table.GroupBy ( "Warehouse, Item, Capacity, Account, Dim1, Dim2, Dim3, ExpenseAccount", "Quantity, Cost" );
	for each row in Table do
		p.Amount = row.Cost;
		p.AccountCr = row.Account;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Warehouse;
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

Procedure commitVAT ( Env )
	
	table = Env.VAT;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountDr = fields.VATAccount;
	p.DimDr1 = fields.VATDim1;
	p.DimDr2 = fields.VATDim2;
	p.DimDr3 = fields.VATDim3;
	p.Operation = Enums.Operations.VATPayable;
	p.Recordset = Env.Registers.General;
	for each row in table do
		p.AccountCr = row.Account;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
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
	if ( Env.DocumentOrderExists ) then
		if ( Env.CheckBalances ) then
			if ( Env.ReservesExist ) then
				Env.Registers.Reserves.LockForUpdate = true;
				Env.Registers.Reserves.Write ();
				Shortage.SqlReserves ( Env );
			else
				Env.Registers.Reserves.Write = true;
			endif;
		endif; 
	else
		Env.Registers.Reserves.Write = true;
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
	if ( Env.DocumentOrderExists ) then
		if ( Env.ReservesExist ) then
			table = SQL.Fetch ( Env, "$ShortageReserves" );
			if ( table.Count () > 0 ) then
				Shortage.Reserves ( Env, table );
				return false;
			endif; 
		endif; 
	endif;
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	if ( not Env.RestoreCost ) then
		registers.RangeStatuses.Write = true;
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
		endif;
		if ( Env.Fields.FuelExpense ) then
			registers.FuelToExpense.Write = true;
		endif;
	endif;
	
EndProcedure

Function makeReserves ( Env )

	table = SQL.Fetch ( Env, "$Reserves" );
	Env.Insert ( "ReservesExist", table.Count () > 0 );
	recordset = Env.Registers.Reserves;
	date = Env.Fields.Date;
	error = false;
	for each row in table do
		if ( row.Invalid ) then
			error = true;
			Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( "Items", row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.RowKey;
		movement.Warehouse = row.Warehouse;
		movement.Quantity = row.Quantity;
	enddo; 
	return not error;
	
EndFunction

Function makeRanges ( Env )
	
	RunRanges.Lock ( Env );
	table = getRanges ( Env );
	recordset = Env.Registers.RangeStatuses;
	date = Env.Fields.Date;
	ref = Env.Ref;
	error = false;
	field = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in table do
		if ( row.NotFound ) then
			error = true;
			p = new Structure ( "Range, Warehouse", row.Range, row.Warehouse );
			Output.RangeNotFound ( p, Output.Row ( "Items", row.LineNumber, "Item" ), ref );
		elsif ( row.Broken ) then
			error = true;
			p = new Structure ( "Range, Quantity, Balance, Warehouse", row.Range, row.Quantity, row.Balance, row.Warehouse );
			Output.RangeIsBroken ( p, Output.Row ( "Items", row.LineNumber, field ), ref );
		else
			movement = recordset.Add ();
			movement.Period = date;
			movement.Range = row.Range;
			movement.Status = Enums.RangeStatuses.WrittenOff;
		endif;
	enddo;
	return not error;
	
EndFunction

Function getRanges ( Env )
	
	s = "
	|// #Ranges
	|select Items.LineNumber as LineNumber, Items.Range as Range, Items.Warehouse,
	|	case when Locations.Range is null
	|			or Statuses.Range is null then true
	|		else false
	|	end as NotFound,
	|	case when Items.Quantity = ( Items.Range.Finish - isnull ( Ranges.Last, Items.Range.Start - 1 ) ) then false else true end Broken,
	|	Items.Quantity as Quantity, Items.Range.Finish - isnull ( Ranges.Last, Items.Range.Start - 1 ) as Balance
	|from (
	|	select Items.Range as Range, Items.Warehouse as Warehouse,
	|		sum ( Items.Quantity ) as Quantity, min ( Items.LineNumber ) as LineNumber
	|	from Items as Items
	|	where Items.Range <> value ( Catalog.Ranges.EmptyRef )
	|	group by Items.Range, Items.Warehouse
	|) as Items
	|	//
	|	// Ranges
	|	//
	|	left join InformationRegister.Ranges as Ranges
	|	on Ranges.Range = Items.Range
	|	//
	|	// Locations
	|	//
	|	left join InformationRegister.RangeLocations.SliceLast ( &Period,
	|		Range in ( select Range from Ranges ) ) as Locations
	|	on Locations.Range = Items.Range
	|	and Locations.Warehouse = Items.Warehouse
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister.RangeStatuses.SliceLast ( &Period,
	|		Range in ( select Range from Ranges ) ) as Statuses
	|	on Statuses.Range = Items.Range
	|	and Statuses.Status = value ( Enum.RangeStatuses.Active )
	|";
	Env.Selection.Add ( s );
	SQL.Prepare ( Env );
	period = ? ( Env.Realtime, undefined, new Boundary ( Env.Fields.Timestamp, BoundaryType.Excluding ) );
	q = Env.Q;
	q.SetParameter ( "Period", period );
	return q.Execute ().Unload ();
	
EndFunction

Procedure makeFuelToExpense ( Env )
	
	recordset = Env.Registers.FuelToExpense;
	table = SQL.Fetch ( Env, "$Items" );
	date = Env.Fields.Date;
	car = Env.Fields.Car;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.Car = car;
		movement.Fuel = row.Item;
		movement.Quantity = row.Quantity;
	enddo;	
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	putTable ( Params, Env );
	putFooter ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
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
	|select Document.Number as Number, Document.Date as Date, Document.Company.FullDescription as Company,
	|	presentation ( Document.Approved ) as Approved, presentation ( Document.ApprovedPosition ) as ApprovedPosition,
	|	presentation ( Document.Head ) as Head, presentation ( Document.HeadPosition ) as HeadPosition,
	|	Document.Memo as Memo
	|from Document.WriteOff as Document
	|where Document.Ref = &Ref
	|;
	|select Items.Item Item, Items.Feature as Feature, Items.Account as Account, Items.Series as Series,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
	|	case when Items.Item.CountPackages then 1 else Items.Capacity end as UnitsInside,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	sum ( Items.QuantityPkg ) as Quantity, min ( LineNumber ) as LineNumber
	|into Items
	|from Document.WriteOff.Items as Items
	|where Items.Ref = &Ref
	|group by Items.Item, Items.Feature, Items.Account, Items.Series, Items.Package, Items.Ref, Items.Capacity,
	|	Items.Warehouse
	|;
	|// #Items
	|select Items.LineNumber as LineNumber, Items.Item.Description as Item, Items.Item.Code as Code,
	|	Items.Unit as Unit, Items.Quantity as Quantity, Cost.Price * Items.UnitsInside as Cost,
	|	Items.Quantity * Cost.Price * Items.UnitsInside as Amount
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
	|	//
	|	// Cost
	|	//
	|	left join (
	|		select Cost.ItemKey as ItemKey, sum ( Cost.Amount ) / sum ( Cost.Quantity ) as Price
	|		from AccumulationRegister.Cost as Cost
	|		where Recorder = &Ref
	|		group by Cost.ItemKey
	|		having sum ( Cost.Quantity ) <> 0 ) as Cost
	|	on Cost.ItemKey = Details.ItemKey
	|order by LineNumber
	|;
	|// #Members
	|select presentation ( Members.Member ) as Member, presentation ( Members.Position ) as Position
	|from Document.WriteOff.Members as Members
	|where Members.Ref = &Ref
	|order by Members.LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure
 
Procedure putTable ( Params, Env )
	
	t = Env.T;
	header = t.GetArea ( "Table" );
	area = t.GetArea ( "Row" );
	header.Parameters.Fill ( Env.Fields );
	tabDoc = Params.TabDoc;
	tabDoc.Put ( header );
	Print.Repeat ( tabDoc );
	table = Env.Items;
	accuracy = Application.Accuracy ();
	p = area.Parameters;
	for each row in table do
		p.Fill ( row );
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo;
	Env.Insert ( "AmountTotal", table.Total ( "Amount" ) );
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	putTotals ( Params, Env );
	tabDoc = Params.TabDoc;
	startStaing = tabDoc.TableHeight + 1;
	putHead ( Params, Env );
	putMembers ( Params, Env );
	tabDoc.Area ( startStaing, , tabDoc.TableHeight ).StayWithNext = true;
	
EndProcedure

Procedure putTotals ( Params, Env )
	
	area = Env.T.GetArea ( "Totals" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.Amount = Env.AmountTotal;
	Params.TabDoc.Put ( area );        
	
EndProcedure 

Procedure putHead ( Params, Env )
	
	area = Env.T.GetArea ( "Head" );
	p = area.Parameters;
	p.Fill ( Env.Fields );
	p.AmountInWords = NumberInWords ( Env.AmountTotal, ? ( Params.SelectedLanguage = "en", "L = en_EN", "L = ru_RU" ) );
	Params.TabDoc.Put ( area );        
	
EndProcedure 

Procedure putMembers ( Params, Env )
	
	members = Env.Members;
	if ( members.Count () = 0 ) then
		return;
	endif; 
	tabDoc = Params.TabDoc;
	t = Env.T;
	tabDoc.Put ( t.GetArea ( "MembersHeader" ) );
	area = t.GetArea ( "MembersRow" );
	p = area.Parameters;
	for each row in members do
		p.Fill ( row );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

#endregion

#endif