#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Production.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	if ( not getData ( Env ) ) then
		return false;
	endif; 
	if ( not checkRows ( Env ) ) then
		return false;
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		if ( not makeValues ( Env ) ) then
			return false;
		endif;
	endif;
	makeItems ( Env );
	makeInternalOrders ( Env );
	makeReserves ( Env );
	makeProductionOrders ( Env );
	makeAllocations ( Env );
	fields = Env.Fields;
	SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	applyProvision ( Env );
	if ( not Env.RestoreCost ) then
		attachSequence ( Env );
		if ( not checkBalances ( Env ) ) then
			return false;
		endif; 
	endif;
	completeDelivery ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Function getData ( Env )
	
	sqlFields ( Env );
	if ( Env.Reposted ) then
		Env.Selection.Add ( Dependencies.SqlDependencies () );
		Env.Selection.Add ( Dependencies.SqlDependants () );
	endif; 
	getFields ( Env );
	setContext ( Env );
	if ( not removeDependency ( Env ) ) then
		return false;
	endif; 
	sqlItems ( Env );
	sqlExpenses ( Env );
	if ( not Env.RestoreCost ) then
		if ( Options.Series () ) then
			sqlEmptySeries ( Env );
		endif;
		sqlSequence ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	sqlInvalidRows ( Env );
	sqlProductsCost ( Env );
	sqlWarehouse ( Env );
	sqlInternalOrders ( Env );
	sqlReserves ( Env );
	sqlServices ( Env );
	if ( Env.ProductionOrderExists ) then
		sqlProductionOrders ( Env );
		sqlProvision ( Env );
	endif;
	sqlAllocation ( Env );
	sqlDelivery ( Env );
	getTables ( Env );
	Env.Insert ( "DistributionRecordsets" );
	return true;
	
EndFunction

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Documents.Warehouse as Warehouse, Documents.Stock as Stock, Documents.Workshop as Workshop,
	|	Documents.Company as Company, Documents.PointInTime as Timestamp, Lots.Ref as Lot, Documents.Date as Date,
	|	isnull ( Distribution.Exist, false ) as DistributionExists
	|from Document.Production as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// Distribution
	|	//
	|	left join ( select top 1 true as Exist
	|			from Document.Production.Services
	|			where Ref = &Ref
	|			and Distribution <> value ( Enum.Distribution.EmptyRef ) ) as Distribution
	|	on true
	|where Documents.Ref = &Ref
	|;
	|// @ProductionOrderExists
	|select top 1 true as Exist
	|from Document.Production.Items as Items
	|where Items.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|and Items.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Production.Services as Services
	|where Services.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|and Services.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Production as Documents
	|where Documents.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|and Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	
EndProcedure 

Procedure setContext ( Env )
	
	Env.Insert ( "CheckBalances", Shortage.Check ( Env.Fields.Company, Env.Realtime, Env.RestoreCost ) );
	Env.Insert ( "ProductionOrderExists", Env.ProductionOrderExists <> undefined and Env.ProductionOrderExists.Exist );

EndProcedure

Function removeDependency ( Env )
	
	if ( Env.Reposted ) then
		if ( dependenciesExist ( Env ) ) then
			return false;
		endif;
		Dependencies.Clear ( Env.Ref, SQL.Fetch ( Env, "$Dependants" ) );
	endif; 
	return true;
	
EndFunction 

Function dependenciesExist ( Env )
	
	table = SQL.Fetch ( Env, "$Dependencies" );
	Dependencies.Show ( table );
	return table.Count () > 0;
	
EndFunction

Procedure sqlItems ( Env )
	
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse, Items.RowKey as RowKey,
	|	Items.Account as Account, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	case when Items.ProductionOrder = value ( Document.ProductionOrder.EmptyRef ) then Items.Ref.ProductionOrder else Items.ProductionOrder end as ProductionOrder
	|into Items
	|from Document.Production.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series, Items.RowKey, Items.DocumentOrder, Items.DocumentOrderRowKey
	|;
	|select ""Services"" as Table, Services.LineNumber as LineNumber, Services.Item as Item, Services.Feature as Feature,
	|	Services.RowKey as RowKey, Services.Quantity as Quantity, Services.Description as Description,
	|	Services.Account as Account, Services.Expense as Expense, Services.Department as Department,
	|	Services.DocumentOrder as DocumentOrder, Services.DocumentOrderRowKey as DocumentOrderRowKey,
	|	case when Services.ProductionOrder = value ( Document.ProductionOrder.EmptyRef ) then Services.Ref.ProductionOrder else Services.ProductionOrder end as ProductionOrder";
	if ( Env.Fields.DistributionExists ) then
		s = s + ", Services.Distribution as Distribution, Services.IntoDocument as IntoDocument";
	endif; 
	s = s + "
	|into Services
	|from Document.Production.Services as Services
	|where Services.Ref = &Ref
	|index by Services.Item, Services.Feature, Services.RowKey, Services.DocumentOrder, Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlExpenses ( Env )
	
	s = "
	|select Expenses.LineNumber as LineNumber, Expenses.Item as Item, Expenses.Feature as Feature, Expenses.Series as Series,
	|	Expenses.Quantity as Quantity, case when Expenses.Item.CountPackages then Expenses.QuantityPkg else Expenses.Quantity end as QuantityPkg,
	|	case when Expenses.Item.CountPackages then Expenses.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Expenses.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Stock else Expenses.Warehouse end as Warehouse,
	|	Expenses.RowKey as RowKey, Expenses.Account as Account, Expenses.ExpenseAccount as ExpenseAccount, Expenses.Expense as Expense,
	|	Expenses.DocumentOrder as DocumentOrder, Expenses.Product as Product, Expenses.ProductFeature as ProductFeature
	|into Expenses
	|from Document.Production.Expenses as Expenses
	|where Expenses.Ref = &Ref
	////|;
	////|// #Expenses
	////|select Expenses.LineNumber as LineNumber, Expenses.Item as Item, Expenses.Feature as Feature, Expenses.Series as Series,
	////|	Expenses.Quantity as Quantity, Expenses.QuantityPkg as QuantityPkg, Expenses.Package as Package,
	////|	Expenses.Warehouse as Warehouse, Expenses.RowKey as RowKey, Expenses.Account as Account, Expenses.ExpenseAccount as ExpenseAccount,
	////|	Expenses.Expense as Expense, Expenses.DocumentOrder as DocumentOrder, Expenses.Product as Product
	////|from Expenses as Expenses
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlEmptySeries ( Env )
	
	s = "
	|// #EmptySeries
	|select Items.LineNumber as LineNumber
	|from Items as Items
	|where Items.Item.Series
	|and Items.Series = value ( Catalog.Series.EmptyRef )
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlSequence ( Env )
	
	s = "
	|// ^SequenceCost
	|select distinct Expenses.Item as Item
	|from Expenses as Expenses
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemKeys ( Env )
	
	s = "
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series, Items.Account as Account,
	|	Details.ItemKey as ItemKey
	|into ItemKeys
	|from Expenses as Items
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
	|	Items.Package as Package, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.QuantityPkg as Quantity, Details.ItemKey as ItemKey,
	|	Items.ExpenseAccount as ExpenseAccount, Items.Expense as Expense,
	|	Items.Product as Product, Items.ProductFeature as ProductFeature
	|from Expenses as Items
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

Procedure sqlInvalidRows ( Env )
	
	s = "
	|// ^InvalidRows
	|select Items.LineNumber as LineNumber, Items.Table as Table, Items.DocumentOrder as DocumentOrder
	|from ( select Items.LineNumber as LineNumber, Items.Table as Table, Items.Item as Item,
	|			Items.Feature as Feature, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey
	|		from Items as Items
	|		union all
	|		select Services.LineNumber, Services.Table, Services.Item, Services.Feature,
	|			Services.DocumentOrderRowKey, Services.DocumentOrder
	|		from Services as Services ) as Items
	|	//
	|	// InternalOrder
	|	//
	|	left join Document.InternalOrder.Items as InternalOrder
	|	on InternalOrder.Ref = Items.DocumentOrder
	|	and InternalOrder.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrder.Item = Items.Item
	|	and InternalOrder.Feature = Items.Feature
	|	//
	|	// SalesOrder
	|	//
	|	left join Document.SalesOrder.Items as SalesOrder
	|	on SalesOrder.Ref = Items.DocumentOrder
	|	and SalesOrder.RowKey = Items.DocumentOrderRowKey
	|	and SalesOrder.Item = Items.Item
	|	and SalesOrder.Feature = Items.Feature
	|where Items.DocumentOrder <> undefined
	|and ( ( Items.DocumentOrder refs Document.InternalOrder and InternalOrder.RowKey is null )
	|	or ( Items.DocumentOrder refs Document.SalesOrder and SalesOrder.RowKey is null ) )
	|";
	if ( Env.ProductionOrderExists ) then
		s = s + "
		|union all
		|select Items.LineNumber, Items.Table, Items.ProductionOrder
		|from Items as Items
		|	//
		|	// ProductionOrders
		|	//
		|	left join Document.ProductionOrder.Items as ProductionOrders
		|	on ProductionOrders.Ref = Items.ProductionOrder
		|	and ProductionOrders.RowKey = Items.RowKey
		|	and ProductionOrders.Item = Items.Item
		|	and ProductionOrders.Feature = Items.Feature
		|where ProductionOrders.RowKey is null
		|union
		|select Services.LineNumber, Services.Table, Services.ProductionOrder
		|from Services as Services
		|	//
		|	// ProductionOrders
		|	//
		|	left join Document.ProductionOrder.Services as ProductionOrders
		|	on ProductionOrders.Ref = Services.ProductionOrder
		|	and ProductionOrders.RowKey = Services.RowKey
		|	and ProductionOrders.Item = Services.Item
		|	and ProductionOrders.Feature = Services.Feature
		|where ProductionOrders.RowKey is null
		|";
	endif; 
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlProductsCost ( Env )
	
	s = "
	|// ^Cost
	|select Items.Item as Item, Items.Item.CostMethod as CostMethod, Items.Package as Package, Items.Feature as Feature,
	|	Items.Series as Series, Items.Warehouse as Warehouse, Items.Account as Account, Details.ItemKey as Itemkey,
	|	Items.QuantityPkg as Quantity, Items.Quantity as Units
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

Procedure sqlWarehouse ( Env )
	
	s = "
	|// ^Items
	|select Goods.Item as Item, Goods.Feature as Feature, Goods.Warehouse as Warehouse, Goods.Package as Package,
	|	Goods.Series as Series, sum ( Goods.QuantityPkg ) as Quantity
	|from Items as Goods
	|	//
	|	// InternalOrder
	|	//
	|	left join Document.InternalOrder as InternalOrder
	|	on InternalOrder.Ref = Goods.DocumentOrder
	|where InternalOrder.Warehouse = Goods.Warehouse
	|or InternalOrder.Warehouse = value ( Catalog.Warehouses.EmptyRef )
	|or Goods.DocumentOrder = undefined
	|group by Goods.Item, Goods.Feature, Goods.Warehouse, Goods.Package, Goods.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlInternalOrders ( Env )
	
	s = "
	|// ^InternalOrders
	|select Goods.DocumentOrder as InternalOrder, Goods.DocumentOrderRowKey as RowKey, Goods.Quantity as Quantity
	|from Items as Goods
	|	//
	|	// InternalOrder
	|	//
	|	join Document.InternalOrder as InternalOrder
	|	on InternalOrder.Ref = Goods.DocumentOrder
	|	and ( InternalOrder.Warehouse = Goods.Warehouse
	|		or InternalOrder.Warehouse = value ( Catalog.Warehouses.EmptyRef ) )
	|union all
	|select DocServices.DocumentOrder, DocServices.DocumentOrderRowKey, DocServices.Quantity
	|from Services as DocServices
	|	//
	|	// InternalOrder
	|	//
	|	join Document.InternalOrder as InternalOrder
	|	on DocServices.DocumentOrder = InternalOrder.Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReserves ( Env )
	
	s = "
	|// ^ReleaseInternalOrders
	|select Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey, Items.Quantity as Quantity,
	|	InternalOrder.Stock as Stock
	|from Items as Items
	|	//
	|	// InternalOrder
	|	//
	|	join Document.InternalOrder.Items as InternalOrder
	|	on InternalOrder.Ref = Items.DocumentOrder
	|	and InternalOrder.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrder.Reservation = value ( Enum.Reservation.Warehouse )
	|;
	|// ^ReserveSalesOrders
	|select Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.Warehouse as Warehouse, Items.Quantity as Quantity
	|from Items as Items
	|where Items.DocumentOrder refs Document.SalesOrder
	|or ( Items.DocumentOrder refs Document.InternalOrder
	|	and cast ( Items.DocumentOrder as Document.InternalOrder ).Warehouse <> Items.Warehouse
	|	and cast ( Items.DocumentOrder as Document.InternalOrder ).Warehouse <> value ( Catalog.Warehouses.EmptyRef ) )
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlServices ( Env )
	
	if ( Env.Fields.DistributionExists ) then
		flag = "true";
	else
		flag = "false";
	endif; 
	s = "
	|// ^Services
	|select Services.Item as Item, Services.Feature as Feature, Services.Account as Account, Services.Expense as Expense,
	|	Services.Department as Department, Services.Description as Description,
	|	sum ( Services.Quantity ) as Quantity, Details.ItemKey as Itemkey,
	|" + flag + " as Distribute
	|from Services as Services
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Services.Item
	|	and Details.Feature = Services.Feature
	|	and Details.Package = value ( Catalog.Packages.EmptyRef )
	|	and Details.Series = value ( Catalog.Series.EmptyRef )
	|	and Details.Warehouse = value ( Catalog.Warehouses.EmptyRef )
	|	and Details.Account = value ( ChartOfAccounts.General.EmptyRef )
	|group by Services.Item, Services.Feature, Services.Account, Services.Expense, Services.Department,
	|	Services.Description, Details.ItemKey, " + flag + "
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProductionOrders ( Env )
	
	s = "
	|// ^ProductionOrders
	|select Items.ProductionOrder as ProductionOrder, Items.RowKey as RowKey, Items.Quantity as Quantity
	|from Items as Items
	|where Items.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|union all
	|select Services.ProductionOrder, Services.RowKey, Services.Quantity
	|from Services as Services
	|where Services.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProvision ( Env )
	
	s = "
	|select Items.ProductionOrder as ProductionOrder, Items.RowKey as RowKey, Items.Quantity as Quantity,
	|	SalesOrders.Ref as SalesOrder, SalesOrders.RowKey as SalesOrderRowKey,
	|	SalesOrders.Ref.Date as Date, SalesOrders.DeliveryDate as DeliveryDate
	|into AllocatedSalesOrders
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.DocumentOrder = Items.ProductionOrder
	|	and SalesOrders.DocumentOrderRowKey = Items.RowKey
	|where Items.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|index by SalesOrder, ProductionOrder, RowKey
	|;
	|select Items.ProductionOrder as ProductionOrder, Items.RowKey as RowKey, Items.Quantity as Quantity,
	|	InternalOrders.Ref as InternalOrder, InternalOrders.RowKey as InternalOrderRowKey,
	|	InternalOrders.Ref.Date as Date, InternalOrders.DeliveryDate as DeliveryDate
	|into AllocatedInternalOrders
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.DocumentOrder = Items.ProductionOrder
	|	and InternalOrders.DocumentOrderRowKey = Items.RowKey
	|where Items.ProductionOrder <> value ( Document.ProductionOrder.EmptyRef )
	|index by InternalOrder, ProductionOrder, RowKey
	|;
	|// ^LockSalesOrders
	|select SalesOrders.SalesOrder as SalesOrder, SalesOrders.RowKey as RowKey
	|from AllocatedSalesOrders as SalesOrders
	|;
	|// ^LockInternalOrders
	|select InternalOrders.InternalOrder as InternalOrder, InternalOrders.RowKey as RowKey
	|from AllocatedInternalOrders as InternalOrders
	|;
	|// ^Provision
	|select Items.ProductionOrder as ProductionOrder, Items.RowKey as RowKey, sum ( Items.Quantity ) as Quantity
	|from Items as Items
	|	//
	|	// Provision
	|	//
	|	join (  select distinct Provision.DocumentOrder as DocumentOrder, Provision.RowKey as RowKey
	|			from AccumulationRegister.Provision as Provision
	|				//
	|				// Items
	|				//
	|				join Items as Items
	|				on Items.ProductionOrder = Provision.DocumentOrder
	|				and Items.RowKey = Provision.RowKey ) as Provision
	|	on Provision.DocumentOrder = Items.ProductionOrder
	|	and Provision.RowKey = Items.RowKey
	|group by Items.ProductionOrder, Items.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlAllocation ( Env )
	
	s = "
	|// ^Allocation
	|select Items.Table as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature,
	|	Items.Quantity as Quantity, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey
	|from Items as Items
	|where Items.DocumentOrder <> undefined
	|union all
	|select Services.Table, Services.LineNumber, Services.Item, Services.Feature, Services.Quantity, Services.DocumentOrder, Services.DocumentOrderRowKey
	|from Services as Services
	|where Services.DocumentOrder <> undefined
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	Env.Q.SetParameter ( "Warehouse", fields.Warehouse );
	Env.Q.SetParameter ( "Stock", fields.Stock );
	Env.Q.SetParameter ( "Timestamp", fields.Timestamp );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Function checkRows ( Env )
	
	ok = true;
	table = SQL.Fetch ( Env, "$InvalidRows" );
	for each row in table do
		Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( row.Table, row.LineNumber, "Item" ), Env.Ref );
		ok = false;
	enddo; 
	if ( Options.Series ()
		and not Env.RestoreCost ) then
		for each row in Env.EmptySeries do
			Output.UndefinedSeries ( , Output.Row ( "Items", row.LineNumber, "Series" ), Env.Ref );
			ok = false;
		enddo; 
	endif;
	return ok;
	
EndFunction

Function makeValues ( Env )

	ItemDetails.Init ( Env );
	lockCost ( Env );
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;
	endif;
	makeCost ( Env, cost );
	commitCost ( Env, cost );
	setCostBound ( Env );
	table = calcProductionCost ( Env, cost );
	makeProductsCost ( Env, table );
	ItemDetails.Save ( Env );
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
	p.Insert ( "AddInTable1FromTable2", "Warehouse, Account, ExpenseAccount, Expense, Product, ProductFeature" );
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
		Output.ItemsCostBalanceError ( msg, Output.Row ( "Expenses", row.LineNumber, column ), Env.Ref );
	enddo;
		
EndProcedure

Procedure makeCost ( Env, Table )
	
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	date = fields.Date;
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
	workshop = fields.Workshop;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = company;
	p.Operation = Enums.Operations.ProductionOutput;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.DimDr1Type = "Expenses";
	p.DimDr2Type = "Departments";
	p.Recordset = Env.Registers.General;
	records = Table.Copy ();
	records.GroupBy ( "Warehouse, Item, Account, ExpenseAccount, Expense", "Quantity, Cost" );
	for each row in records do
		p.Amount = row.Cost;
		p.AccountCr = row.Account;
		p.QuantityCr = row.Quantity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Warehouse;
		p.AccountDr = row.ExpenseAccount;
		p.DimDr1 = row.Expense;
		p.DimDr2 = workshop;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.ProductionOutput ) then
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

Function calcProductionCost ( Env, Cost )
	
	items = SQL.Fetch ( Env, "$Cost" );
	p = new Structure ();
	p.Insert ( "FilterColumns", "Item" );
	p.Insert ( "DistribColumnsTable1", "Cost" );
	p.Insert ( "DistribColumnsTable2", "Units" );
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "AssignСоlumnsTаble1", "Expense, ExpenseAccount" );
	p.Insert ( "AssignСоlumnsTаble2", "ItemKey, Item, Package, Feature, Series, Warehouse, Account" );
	p.Insert ( "DistributeTables" );
	Cost.Columns.Delete ( "Item" );
	Cost.Columns.Product.Name = "Item";
	result = CollectionsSrv.Combine ( Cost, items, p );
	if ( Cost.Count () > 0 ) then
		number = new TypeDescription ( "Number" );
		Cost.Columns.Add ( "Common", number );
		items.Columns.Add ( "Common", number );
		p.Insert ( "FilterColumns", "Common" );
		CollectionsSrv.Join ( result, CollectionsSrv.Combine ( Cost, items, p ) );
	endif;
	result.GroupBy ( "ItemKey, Item, Package, Feature, Series, Warehouse, Account, CostMethod, Expense, ExpenseAccount", "Units, Cost" );
	return result;
	
EndFunction

Procedure makeProductsCost ( Env, Table )
	
	p = GeneralRecords.GetParams ();
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	for each row in Table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		movement.ItemKey = row.ItemKey;
		if ( row.CostMethod = Enums.Cost.FIFO ) then
			if ( lot = null ) then
				lot = newLot ( Env );
				fields.Lot = lot;
			endif; 
			movement.Lot = lot;
		endif; 
		movement.Quantity = row.Units;
		movement.Amount = row.Cost;
		commitProductCost ( Env, p, row );
	enddo; 
	
EndProcedure

Function newLot ( Env )
	
	obj = Catalogs.Lots.CreateItem ();
	obj.Date = Env.Fields.Date;
	obj.Document = Env.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction

Procedure commitProductCost ( Env, Params, Row )
	
	fields = Env.Fields;
	Params.Date = fields.Date;
	Params.Company = fields.Company;
	Params.AccountDr = row.Account;
	Params.AccountCr = row.ExpenseAccount;
	Params.Operation = Enums.Operations.ProductionOutput;
	Params.Amount = row.Cost;
	Params.QuantityDr = row.Units;
	Params.DimDr1 = row.Item;
	Params.DimDr2 = row.Warehouse;
	Params.DimCr1 = row.Expense;
	Params.DimCr2 = fields.Workshop;
	Params.Recordset = Env.Registers.General;
	GeneralRecords.Add ( Params );

EndProcedure

Procedure makeItems ( Env )

	recordset = Env.Registers.Items;
	table = SQL.Fetch ( Env, "$Items" );
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeInternalOrders ( Env )

	recordset = Env.Registers.InternalOrders;
	table = SQL.Fetch ( Env, "$InternalOrders" );
	Env.Insert ( "InternalOrdersExist", ( table.Count () > 0 ) );
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.InternalOrder = row.InternalOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeReserves ( Env )

	recordset = Env.Registers.Reserves;
	table = SQL.Fetch ( Env, "$ReserveSalesOrders" );
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Warehouse = row.Warehouse;
		movement.Quantity = row.Quantity;
	enddo; 
	table = SQL.Fetch ( Env, "$ReleaseInternalOrders" );
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Warehouse = row.Stock;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeProductionOrders ( Env )

	if ( not Env.ProductionOrderExists ) then
		return;
	endif;
	table = SQL.Fetch ( Env, "$ProductionOrders" );
	Env.Insert ( "AllocationExists", false );
	recordset = Env.Registers.ProductionOrders;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.ProductionOrder = row.ProductionOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure
 
Procedure makeAllocations ( Env )
	
	if ( Env.ProductionOrderExists ) then
		return;
	endif;
	table = SQL.Fetch ( Env, "$Allocation" );
	Env.Insert ( "AllocationExists", ( table.Count () > 0 ) );
	recordset = Env.Registers.Allocation;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure applyProvision ( Env )

	if ( not Env.ProductionOrderExists ) then
		return;
	endif;
	provision = SQL.Fetch ( Env, "$Provision" );
	if ( provision.Count () = 0 ) then
		return;
	endif; 
	lockOrders ( Env );
	getOrdersBalances ( Env );
	orders = defineOrders ( Env, provision );
	performOrders ( Env, orders );
	makeProvision ( Env, provision );
	
EndProcedure

Procedure lockOrders ( Env )
	
	lock = new DataLock ();
	salesOrders = SQL.Fetch ( Env, "$LockSalesOrders" );
	if ( salesOrders.Count () > 0 ) then
		item = lock.Add ( "AccumulationRegister.SalesOrders" );
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = salesOrders;
		item.UseFromDataSource ( "SalesOrder", "SalesOrder" );
		item.UseFromDataSource ( "RowKey", "RowKey" );
	endif; 
	internalOrders = SQL.Fetch ( Env, "$LockInternalOrders" );
	if ( internalOrders.Count () > 0 ) then
		item = lock.Add ( "AccumulationRegister.InternalOrders" );
		item.Mode = DataLockMode.Exclusive;
		item.DataSource = internalOrders;
		item.UseFromDataSource ( "InternalOrder", "InternalOrder" );
		item.UseFromDataSource ( "RowKey", "RowKey" );
	endif; 
	lock.Lock ();
	
EndProcedure

Procedure getOrdersBalances ( Env )
	
	sqlOrdersBalances ( Env );
	SQL.Prepare ( Env );
	SQL.Unload ( Env );
	
EndProcedure

Procedure sqlOrdersBalances ( Env )
	
	s = "
	|select SalesOrders.RowKey as RowKey, SalesOrders.SalesOrder as SalesOrder,
	|	SalesOrders.SalesOrderRowKey as SalesOrderRowKey, SalesOrders.Date as Date,
	|	SalesOrders.DeliveryDate as DeliveryDate, isnull ( Balances.QuantityBalance, 0 ) as Quantity
	|into SalesOrdersBalances
	|from AllocatedSalesOrders as SalesOrders
	|	//
	|	// Balances
	|	//
	|	left join AccumulationRegister.SalesOrders.Balance ( ,
	|		( SalesOrder, RowKey ) in ( select SalesOrder, RowKey from AllocatedSalesOrders ) ) as Balances
	|	on Balances.SalesOrder = SalesOrders.SalesOrder
	|	and Balances.RowKey = SalesOrders.SalesOrderRowKey
	|;
	|select InternalOrders.RowKey as RowKey, InternalOrders.InternalOrder as InternalOrder,
	|	InternalOrders.InternalOrder.Warehouse as Warehouse, InternalOrders.InternalOrderRowKey as InternalOrderRowKey,
	|	InternalOrders.Date as Date, InternalOrders.DeliveryDate as DeliveryDate,
	|	isnull ( Balances.QuantityBalance, 0 ) as Quantity	
	|into InternalOrdersBalances
	|from AllocatedInternalOrders as InternalOrders
	|	//
	|	// Balances
	|	//
	|	left join AccumulationRegister.InternalOrders.Balance ( ,
	|		( InternalOrder, RowKey ) in ( select InternalOrder, RowKey from AllocatedInternalOrders ) ) as Balances
	|	on Balances.InternalOrder = InternalOrders.InternalOrder
	|	and Balances.RowKey = InternalOrders.InternalOrderRowKey
	|;
	|// #OrdersBalances
	|select Items.RowKey as RowKey, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.Quantity as Quantity, Items.Warehouse as Warehouse
	|from ( select Items.RowKey as RowKey, Items.SalesOrder as DocumentOrder, Items.SalesOrderRowKey as DocumentOrderRowKey,
	|		Items.Date as Date, Items.DeliveryDate as DeliveryDate, Items.Quantity as Quantity, null as Warehouse
	|		from SalesOrdersBalances as Items
	|		union all
	|		select Items.RowKey, Items.InternalOrder, Items.InternalOrderRowKey, Items.Date, Items.DeliveryDate,
	|			Items.Quantity, Items.Warehouse
	|		from InternalOrdersBalances as Items ) as Items
	|order by Items.DeliveryDate, Items.Date
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function defineOrders ( Env, Provision )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "RowKey" );
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "DecreasingColumns2", "Quantity" );
	return CollectionsSrv.Decrease ( Env.OrdersBalances, Provision, p );
	
EndFunction

Procedure performOrders ( Env, Table )
	
	salesOrder = Type ( "DocumentRef.SalesOrder" );
	for each row in Table do
		if ( TypeOf ( row.DocumentOrder ) = salesOrder ) then
			reserve ( Env, row );
		else
			performInternalOrder ( Env, row );
		endif; 
	enddo; 
	
EndProcedure

Procedure reserve ( Env, Row )
	
	recordset = Env.Registers.Reserves;
	movement = recordset.AddReceipt ();
	movement.Period = Env.Fields.Date;
	movement.DocumentOrder = Row.DocumentOrder;
	movement.RowKey = Row.DocumentOrderRowKey;
	movement.Warehouse = Row.Warehouse;
	movement.Quantity = Row.Quantity;
	
EndProcedure

Procedure performInternalOrder ( Env, Row )
	
	fields = Env.Fields;
	if ( ValueIsFilled ( Row.Warehouse ) and Row.Warehouse <> fields.Warehouse ) then
		reserve ( Env, Row );
	else
		recordset = Env.Registers.InternalOrders;
		movement = recordset.AddExpense ();
		movement.Period = fields.Date;
		movement.InternalOrder = Row.DocumentOrder;
		movement.RowKey = Row.DocumentOrderRowKey;
		movement.Quantity = Row.Quantity;
	endif; 
	
EndProcedure

Procedure makeProvision ( Env, Table )
	
	recordset = Env.Registers.Provision;
	date = Env.Fields.Date;
	for each row in Table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.ProductionOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
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
		movement.Company= company;
		movement.Item = row.Item;
	enddo;
	recordset.Write ();
	
EndProcedure

Function checkBalances ( Env )

	registers = Env.Registers;
	internalOrders = registers.InternalOrders;
	if ( Env.InternalOrdersExist ) then
		internalOrders.LockForUpdate = true;
		internalOrders.Write ();
		Shortage.SqlInternalOrders ( Env );
	else
		internalOrders.Write = true;
	endif;
	allocation = registers.Allocation;
	if ( Env.AllocationExists ) then
		allocation.LockForUpdate = true;
		allocation.Write ();
		Shortage.SqlAllocation ( Env );
	else
		allocation.Write = true;
	endif;
	purchaseOrders = registers.ProductionOrders;
	if ( Env.ProductionOrderExists ) then
		purchaseOrders.LockForUpdate = true;
		purchaseOrders.Write ();
		Shortage.SqlProductionOrders ( Env );
	else
		purchaseOrders.Write = true;
	endif; 
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
	if ( Env.InternalOrdersExist ) then
		table = SQL.Fetch ( Env, "$ShortageInternalOrders" );
		if ( table.Count () > 0 ) then
			Shortage.Orders ( Env, table );
			return false;
		endif; 
	endif; 
	if ( Env.AllocationExists ) then
		table = SQL.Fetch ( Env, "$ShortageAllocation" );
		if ( table.Count () > 0 ) then
			Shortage.Provision ( Env, table );
			return false;
		endif; 
	endif; 
	if ( Env.ProductionOrderExists ) then
		table = SQL.Fetch ( Env, "$ShortageProductionOrders" );
		if ( table.Count () > 0 ) then
			Shortage.ProductionOrders ( Env, table );
			return false;
		endif; 
	endif; 
	if ( Env.CheckBalances ) then
		table = SQL.Fetch ( Env, "$ShortageItems" );
		if ( table.Count () > 0 ) then
			Shortage.Items ( Env, table );
			return false;
		endif; 
	endif; 
	return true;
		
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	registers.Items.Write = true;
	registers.Cost.Write = true;
	registers.Reserves.Write = true;
	registers.Provision.Write = true;
	
EndProcedure

Procedure sqlDelivery ( Env )
	
	s = "
	|select Tasks.Ref as Task, Tasks.RoutePoint as RoutePoint,
	|	cast ( Tasks.BusinessProcess as BusinessProcess.InternalOrder ).InternalOrder as InternalOrder
	|into Tasks
	|from Task.Task as Tasks
	|where not Tasks.DeletionMark
	|and not Tasks.Executed
	|and Tasks.RoutePoint = value ( BusinessProcess.InternalOrder.RoutePoint.Delivery )
	|;
	|// #Delivery
	|select Tasks.Task as Task, Tasks.RoutePoint as RoutePoint
	|from Tasks as Tasks
	|	//
	|	// InternalOrders
	|	//
	|	join (	select Items.DocumentOrder as InternalOrder
	|			from Items as Items
	|			where Items.DocumentOrder refs Document.InternalOrder
	|			and cast ( Items.DocumentOrder as Document.InternalOrder ).Warehouse = Items.Warehouse
	|			union
	|			select Services.DocumentOrder
	|			from Services as Services
	|			where Services.DocumentOrder refs Document.InternalOrder
	|			) as InternalOrders
	|	on InternalOrders.InternalOrder = Tasks.InternalOrder
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure completeDelivery ( Env )
	
	table = Env.Delivery;
	for each row in table do
		task = row.Task.GetObject ();
		if ( task.CheckExecution () ) then
			task.ExecuteTask ();
		endif; 
	enddo; 
	
EndProcedure 

#endregion

#endif