Function Check ( Company, Realtime, RestoreCost ) export
	
	if ( RestoreCost ) then
		return false;
	else
		mode = Options.BalanceControl ( Company );
		return mode = Enums.BalanceControl.Allways
		or ( mode = Enums.BalanceControl.Realtime
			and Realtime );
	endif; 

EndFunction

Procedure SqlProvision ( Env ) export

	s = "
	|select ItemProvisionBalance.DocumentOrder as DocumentOrder, ItemProvisionBalance.RowKey as RowKey,
	|	- ItemProvisionBalance.QuantityBalance as QuantityBalance
	|into ItemProvisionBalance
	|from AccumulationRegister.Provision.Balance ( , ( DocumentOrder, RowKey )
	|	in ( select DocumentOrder, RowKey from AccumulationRegister.Provision where Recorder = &Ref ) ) as ItemProvisionBalance
	|where ItemProvisionBalance.QuantityBalance < 0
	|;
	|// ^ShortageProvision
	|select Items.LineNumber as LineNumber, presentation ( Items.Item ) as Item, presentation ( Items.Item.Unit ) as Unit,
	|	ItemProvisionBalance.QuantityBalance as Quantity, Items.Quantity - ItemProvisionBalance.QuantityBalance as QuantityBalance,
	|	ItemProvisionBalance.DocumentOrder as DocumentOrder
	|from ItemProvisionBalance as ItemProvisionBalance
	|	//
	|	// Items
	|	//
	|	join Items as Items
	|	on ItemProvisionBalance.DocumentOrder = Items.DocumentOrder
	|	and ItemProvisionBalance.RowKey = Items.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure Provision ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, Quantity, QuantityBalance, DocumentOrder" );
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in Table do
		p.DocumentOrder = row.DocumentOrder;
		p.Item = row.Item;
		p.Quantity = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		p.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		Output.AllocationBalanceError ( p, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlInternalOrders ( Env ) export
	
	s = "
	|select InternalOrdersBalance.InternalOrder as InternalOrder, InternalOrdersBalance.RowKey as RowKey,
	|	- InternalOrdersBalance.QuantityBalance as QuantityBalance
	|into InternalOrdersBalance
	|from AccumulationRegister.InternalOrders.Balance ( , ( InternalOrder, RowKey ) in ( select InternalOrder, RowKey
	|	from AccumulationRegister.InternalOrders where Recorder = &Ref ) ) as InternalOrdersBalance
	|where InternalOrdersBalance.QuantityBalance < 0
	|;
	|// ^ShortageInternalOrders
	|select InternalOrdersBalance.InternalOrder as InternalOrder, Items.LineNumber as LineNumber, Items.Table as Table, presentation ( Items.Item ) as Item,
	|	presentation ( Items.Item.Unit ) as Unit, InternalOrdersBalance.QuantityBalance as Quantity,
	|	Items.Quantity - InternalOrdersBalance.QuantityBalance as QuantityBalance
	|from InternalOrdersBalance as InternalOrdersBalance
	|	join Items as Items
	|	on InternalOrdersBalance.InternalOrder = Items.DocumentOrder
	|	and InternalOrdersBalance.RowKey = Items.DocumentOrderRowKey
	|union all
	|select InternalOrdersBalance.InternalOrder, Services.LineNumber, Services.Table, presentation ( Services.Item ), presentation ( Services.Item.Unit ),
	|	InternalOrdersBalance.QuantityBalance, Services.Quantity - InternalOrdersBalance.QuantityBalance
	|from InternalOrdersBalance as InternalOrdersBalance
	|	join Services as Services
	|	on InternalOrdersBalance.InternalOrder = Services.DocumentOrder
	|	and InternalOrdersBalance.RowKey = Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure Orders ( Env, Table ) export
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	p = Posting.Msg ( Env, "Item, Resource, ResourceBalance, DocumentOrder" );
	for each row in Table do
		p.DocumentOrder = row.InternalOrder;
		p.Item = row.Item;
		p.Resource = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		p.ResourceBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		Output.OrdersBalanceError ( p, Output.Row ( row.Table, row.LineNumber, column ), Env.Ref );
	enddo; 
	
EndProcedure

Procedure SqlPurchaseOrders ( Env ) export
	
	s = "
	|select PurchaseOrdersBalance.PurchaseOrder as PurchaseOrder, PurchaseOrdersBalance.RowKey as RowKey,
	|	- PurchaseOrdersBalance.QuantityBalance as QuantityBalance, - PurchaseOrdersBalance.AmountBalance as AmountBalance
	|into PurchaseOrdersBalance
	|from AccumulationRegister.PurchaseOrders.Balance ( , ( PurchaseOrder, RowKey ) in ( select distinct PurchaseOrder, RowKey
	|	from AccumulationRegister.PurchaseOrders where Recorder = &Ref ) ) as PurchaseOrdersBalance
	|where PurchaseOrdersBalance.QuantityBalance < 0
	|or PurchaseOrdersBalance.AmountBalance < 0
	|;
	|// ^ShortagePurchaseOrders
	|select Items.Table as Table, Items.LineNumber as LineNumber, presentation ( Items.Item ) as Item,
	|	presentation ( Items.Item.Unit ) as Unit, presentation ( Items.PurchaseOrder ) as PurchaseOrder,
	|	PurchaseOrdersBalance.QuantityBalance as Quantity, PurchaseOrdersBalance.AmountBalance as Amount,
	|	Items.Quantity - PurchaseOrdersBalance.QuantityBalance as QuantityBalance, Items.Amount - PurchaseOrdersBalance.AmountBalance as AmountBalance
	|from PurchaseOrdersBalance
	|	join Items as Items
	|	on Items.PurchaseOrder = PurchaseOrdersBalance.PurchaseOrder
	|	and Items.RowKey = PurchaseOrdersBalance.RowKey
	|union all
	|select Services.Table, Services.LineNumber, presentation ( Services.Item ), presentation ( Services.Item.Unit ), presentation ( Services.PurchaseOrder ),
	|	PurchaseOrdersBalance.QuantityBalance, PurchaseOrdersBalance.AmountBalance, Services.Quantity - PurchaseOrdersBalance.QuantityBalance,
	|	Services.Amount - PurchaseOrdersBalance.AmountBalance
	|from PurchaseOrdersBalance
	|	join Services as Services
	|	on Services.PurchaseOrder = PurchaseOrdersBalance.PurchaseOrder
	|	and Services.RowKey = PurchaseOrdersBalance.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure PurchaseOrders ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, Resource, ResourceBalance, DocumentOrder" );
	qtyColumn = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in Table do
		p.DocumentOrder = row.PurchaseOrder;
		p.Item = row.Item;
		if ( row.Quantity > 0 ) then
			p.Resource = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
			p.ResourceBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
			column = qtyColumn;
		elsif ( row.Amount > 0 ) then
			p.Resource = Conversion.NumberToMoney ( row.Amount, Env.Fields.Currency );
			p.ResourceBalance = Conversion.NumberToMoney ( row.AmountBalance, Env.Fields.Currency );
			column = "Amount";
		endif; 
		Output.OrdersBalanceError ( p, Output.Row ( row.Table, row.LineNumber, column ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlProductionOrders ( Env ) export
	
	s = "
	|select ProductionOrdersBalance.ProductionOrder as ProductionOrder, ProductionOrdersBalance.RowKey as RowKey,
	|	- ProductionOrdersBalance.QuantityBalance as QuantityBalance
	|into ProductionOrdersBalance
	|from AccumulationRegister.ProductionOrders.Balance ( , ( ProductionOrder, RowKey ) in ( select distinct ProductionOrder, RowKey
	|	from AccumulationRegister.ProductionOrders where Recorder = &Ref ) ) as ProductionOrdersBalance
	|where ProductionOrdersBalance.QuantityBalance < 0
	|;
	|// ^ShortageProductionOrders
	|select Items.Table as Table, Items.LineNumber as LineNumber, presentation ( Items.Item ) as Item,
	|	presentation ( Items.Item.Unit ) as Unit, presentation ( Items.ProductionOrder ) as ProductionOrder,
	|	ProductionOrdersBalance.QuantityBalance as Quantity,
	|	Items.Quantity - ProductionOrdersBalance.QuantityBalance as QuantityBalance
	|from ProductionOrdersBalance
	|	join Items as Items
	|	on Items.ProductionOrder = ProductionOrdersBalance.ProductionOrder
	|	and Items.RowKey = ProductionOrdersBalance.RowKey
	|union all
	|select Services.Table, Services.LineNumber, presentation ( Services.Item ), presentation ( Services.Item.Unit ), presentation ( Services.ProductionOrder ),
	|	ProductionOrdersBalance.QuantityBalance, Services.Quantity - ProductionOrdersBalance.QuantityBalance
	|from ProductionOrdersBalance
	|	join Services as Services
	|	on Services.ProductionOrder = ProductionOrdersBalance.ProductionOrder
	|	and Services.RowKey = ProductionOrdersBalance.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure ProductionOrders ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, Resource, ResourceBalance, DocumentOrder" );
	qtyColumn = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in Table do
		p.DocumentOrder = row.ProductionOrder;
		p.Item = row.Item;
		p.Resource = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		p.ResourceBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		Output.OrdersBalanceError ( p, Output.Row ( row.Table, row.LineNumber, qtyColumn ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlAllocation ( Env ) export
	
	s = "
	|select AllocationBalance.DocumentOrder as DocumentOrder, AllocationBalance.RowKey as RowKey,
	|	- AllocationBalance.QuantityBalance as QuantityBalance
	|into AllocationBalance
	|from AccumulationRegister.Allocation.Balance ( , ( DocumentOrder, RowKey )
	|	in ( select DocumentOrder, RowKey from AccumulationRegister.Allocation where Recorder = &Ref ) ) as AllocationBalance
	|where AllocationBalance.QuantityBalance < 0
	|;
	|// ^ShortageAllocation
	|select Items.LineNumber as LineNumber, Items.Table as Table, presentation ( Items.Item ) as Item, presentation ( Items.Item.Unit ) as Unit,
	|	AllocationBalance.QuantityBalance as Quantity, Items.Quantity - AllocationBalance.QuantityBalance as QuantityBalance,
	|	AllocationBalance.DocumentOrder as DocumentOrder
	|from AllocationBalance as AllocationBalance
	|	join Items as Items
	|	on AllocationBalance.DocumentOrder = Items.DocumentOrder
	|	and AllocationBalance.RowKey = Items.DocumentOrderRowKey
	|union all
	|select Services.LineNumber, Services.Table, presentation ( Services.Item ), presentation ( Services.Item.Unit ),
	|	AllocationBalance.QuantityBalance, Services.Quantity - AllocationBalance.QuantityBalance, AllocationBalance.DocumentOrder
	|from AllocationBalance as AllocationBalance
	|	join Services as Services
	|	on AllocationBalance.DocumentOrder = Services.DocumentOrder
	|	and AllocationBalance.RowKey = Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure SqlItems ( Env ) export

	type = Env.Type;
	if ( type = Type ( "DocumentRef.Disassembling" ) ) then
		s = "
		|// ^ShortageItems
		|select presentation ( Set.Warehouse ) as Warehouse, presentation ( Set.Item ) as Item,
		|	Set.Unit as Unit, - Balances.QuantityBalance as Quantity,
		|	sum ( Set.QuantityPkg ) + Balances.QuantityBalance as QuantityBalance
		|from AccumulationRegister.Items.Balance ( , ( Warehouse, Item, Feature, Package )
		|	in ( select distinct Warehouse, Item, Feature, Package from AccumulationRegister.Items where Recorder = &Ref ) ) as Balances
		|	//
		|	// Set
		|	//
		|	join Set as Set
		|	on Set.Item = Balances.Item
		|	and Set.Feature = Balances.Feature
		|	and Set.Warehouse = Balances.Warehouse
		|	and Set.Package = Balances.Package
		|where Balances.QuantityBalance < 0
		|group by Set.Warehouse, Set.Item, Set.Unit, Balances.QuantityBalance
		|";
	elsif ( type = Type ( "DocumentRef.WriteOffForm" ) ) then
		s = "
		|// ^ShortageItems
		|select presentation ( Documents.Warehouse ) as Warehouse, presentation ( Documents.Item ) as Item,
		|	Documents.Item.Unit.Code as Unit, - Balances.QuantityBalance as Quantity,
		|	1 + Balances.QuantityBalance as QuantityBalance
		|from AccumulationRegister.Items.Balance ( , ( Warehouse, Item, Feature, Package )
		|	in ( select distinct Warehouse, Item, Feature, Package from AccumulationRegister.Items where Recorder = &Ref ) ) as Balances
		|	//
		|	// Documents
		|	//
		|	join Document.WriteOffForm as Documents
		|	on Documents.Item = Balances.Item
		|	and Documents.Feature = Balances.Feature
		|	and Documents.Warehouse = Balances.Warehouse
		|	and value ( Catalog.Packages.EmptyRef ) = Balances.Package
		|where Balances.QuantityBalance < 0
		|";
	else
		if ( type = Type ( "DocumentRef.InternalOrder" )
			or type = Type ( "DocumentRef.SalesOrder" ) ) then
			warehouse = "Stock";
		elsif ( type = Type ( "DocumentRef.Transfer" ) ) then
			warehouse = "Sender";
		else
			warehouse = "Warehouse";
		endif; 
	s = "
	|// ^ShortageItems
	|select min ( Items.LineNumber ) as LineNumber, presentation ( Items." + warehouse + " ) as Warehouse, presentation ( Items.Item ) as Item,
	|	isnull ( Items.Package.Description, Items.Item.Unit.Code ) as Unit, - Balances.QuantityBalance as Quantity,
	|	sum ( Items.QuantityPkg ) + Balances.QuantityBalance as QuantityBalance
	|from AccumulationRegister.Items.Balance ( , ( Warehouse, Item, Feature, Package )
	|	in ( select distinct Warehouse, Item, Feature, Package from AccumulationRegister.Items where Recorder = &Ref ) ) as Balances
	|	//
	|	// Items
	|	//
	|	join Items as Items
	|	on Items.Item = Balances.Item
	|	and Items.Feature = Balances.Feature
	|	and Items." + warehouse + " = Balances.Warehouse
	|	and Items.Package = Balances.Package
	|where Balances.QuantityBalance < 0
	|group by Items." + warehouse + ", Items.Item, Items.Package, Balances.QuantityBalance
	|";
	endif;
	Env.Selection.Add ( s );
	
EndProcedure

Procedure Items ( Env, Table ) export
	
	field = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	type = Env.Type;
	disassembling = Type ( "DocumentRef.Disassembling" );
	production = Type ( "DocumentRef.Production" );
	form = Type ( "DocumentRef.WriteOffForm" );
	p = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in table do
		p.Warehouse = row.Warehouse;
		p.Item = row.Item;
		p.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		p.Quantity = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		if ( type = disassembling ) then
			Output.WarehouseBalanceError ( p, field, Env.Ref );
		elsif ( type = production ) then
			Output.WarehouseBalanceError ( p, Output.Row ( "Expenses", row.LineNumber, field ), Env.Ref );
		elsif ( type = form ) then
			OutputCont.FormBalanceError ( p, "Range", Env.Fields.Base );
		else
			Output.WarehouseBalanceError ( p, Output.Row ( "Items", row.LineNumber, field ), Env.Ref );
		endif;
	enddo; 

EndProcedure

Procedure SqlSalesOrders ( Env ) export

	s = "
	|select Balances.SalesOrder as SalesOrder, Balances.RowKey as RowKey,
	|	- Balances.QuantityBalance as QuantityBalance, - Balances.AmountBalance as AmountBalance
	|into Balances
	|from AccumulationRegister.SalesOrders.Balance ( , ( SalesOrder, RowKey ) in ( select distinct SalesOrder, RowKey from AccumulationRegister.SalesOrders
	|	where Recorder = &Ref ) ) as Balances
	|where Balances.QuantityBalance < 0
	|or Balances.AmountBalance < 0
	|;
	|// ^ShortageSalesOrders
	|select Items.Table as Table, Items.LineNumber as LineNumber, presentation ( Items.Item ) as Item, presentation ( Items.Item.Unit ) as Unit,
	|	presentation ( Items.SalesOrder ) as SalesOrder,
	|	Items.Quantity - Balances.QuantityBalance as Quantity,
	|	Items.Amount - Balances.AmountBalance as Amount,
	|	Balances.QuantityBalance as QuantityBalance, Balances.AmountBalance as AmountBalance
	|from Balances
	|	join Items as Items
	|	on Items.SalesOrder = Balances.SalesOrder
	|	and Items.RowKey = Balances.RowKey
	|union all
	|select Services.Table, Services.LineNumber, presentation ( Services.Item ), presentation ( Services.Item.Unit ),
	|	presentation ( Services.SalesOrder ),
	|	Services.Quantity - Balances.QuantityBalance,
	|	Services.Amount - Balances.AmountBalance,
	|	Balances.QuantityBalance, Balances.AmountBalance
	|from Balances
	|	join Services as Services
	|	on Services.SalesOrder = Balances.SalesOrder
	|	and Services.RowKey = Balances.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure SalesOrder ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, Resource, ResourceBalance, DocumentOrder" );
	qtyColumn = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	for each row in Table do
		p.DocumentOrder = row.SalesOrder;
		p.Item = row.Item;
		if ( row.QuantityBalance > 0 ) then
			p.Resource = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
			p.ResourceBalance = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
			column = qtyColumn;
		elsif ( row.AmountBalance > 0 ) then
			p.Resource = Conversion.NumberToMoney ( row.AmountBalance, Env.Fields.Currency );
			p.ResourceBalance = Conversion.NumberToMoney ( row.Amount, Env.Fields.Currency );
			column = "Amount";
		endif; 
		Output.OrdersBalanceError ( p, Output.Row ( row.Table, row.LineNumber, column ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlReserves ( Env ) export

	type = Env.Type;
	if ( type = Type ( "DocumentRef.Transfer" )
		or type = Type ( "DocumentRef.WriteOff" )
		or type = Type ( "DocumentRef.VendorReturn" ) ) then
		order = "DocumentOrder";
	else
		order = "SalesOrder";
	endif; 
	s = "
	|// ^ShortageReserves
	|select Items.LineNumber as LineNumber, presentation ( Balances.Warehouse ) as Warehouse,
	|	presentation ( Items.Item ) as Item, presentation ( Items.Item.Unit ) as Unit,
	|	- Balances.QuantityBalance as Quantity, Items.Quantity + Balances.QuantityBalance as QuantityBalance
	|from Items as Items
	|	//
	|	// Reserves
	|	//
	|	join AccumulationRegister.Reserves.Balance ( , ( DocumentOrder, RowKey, Warehouse )
	|		in ( select distinct DocumentOrder, RowKey, Warehouse from AccumulationRegister.Reserves where Recorder = &Ref ) ) as Balances
	|	on Balances.QuantityBalance < 0
	|	and Balances.DocumentOrder = Items." + order + "
	|	and Balances.RowKey = Items.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure Reserves ( Env, Table ) export
	
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	p = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
	for each row in table do
		p.Warehouse = row.Warehouse;
		p.Item = row.Item;
		p.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		p.Quantity = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		Output.ReservationBalanceError ( p, Output.Row ( "Items", row.LineNumber, column ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlVendorServices ( Env ) export

	s = "
	|// ^ShortageVendorServices
	|select Services.LineNumber as LineNumber, presentation ( Services.Item ) as Item, presentation ( Services.Item.Unit ) as Unit,
	|	- Balances.QuantityBalance as Quantity, Services.Quantity + Balances.QuantityBalance as QuantityBalance
	|from Services as Services
	|	join AccumulationRegister.VendorServices.Balance ( , ( SalesOrder, RowKey )
	|		in ( select distinct SalesOrder, RowKey from AccumulationRegister.VendorServices where Recorder = &Ref ) ) as Balances
	|	on Balances.QuantityBalance < 0
	|	and Balances.SalesOrder = Services.SalesOrder
	|	and Balances.RowKey = Services.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure VendorServices ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, QuantityBalance, Quantity" );
	for each row in table do
		p.Item = row.Item;
		p.QuantityBalance = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
		p.Quantity = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
		Output.VendorServicesBalanceError ( p, Output.Row ( "Services", row.LineNumber, "Quantity" ), Env.Ref );
	enddo; 

EndProcedure

Procedure SqlWork ( Env ) export

	s = "
	|select Balances.TimeEntry as TimeEntry, Balances.RowKey as RowKey,
	|	- Balances.QuantityBalance as QuantityBalance, - Balances.AmountBalance as AmountBalance
	|into Work
	|from AccumulationRegister.Work.Balance ( , ( TimeEntry, RowKey ) in ( select distinct TimeEntry, RowKey from AccumulationRegister.Work
	|	where Recorder = &Ref ) ) as Balances
	|where Balances.QuantityBalance < 0
	|or Balances.AmountBalance < 0
	|;
	|// ^ShortageWork
	|select Items.Table as Table, Items.LineNumber as LineNumber, presentation ( Items.Item ) as Item, presentation ( Items.Item.Unit ) as Unit,
	|	presentation ( Items.TimeEntry ) as TimeEntry,
	|	Items.Quantity - Balances.QuantityBalance as Quantity,
	|	Items.Amount - Balances.AmountBalance as Amount,
	|	Balances.QuantityBalance as QuantityBalance, Balances.AmountBalance as AmountBalance
	|from Work as Balances
	|	join Items as Items
	|	on Items.TimeEntry = Balances.TimeEntry
	|	and Items.RowKey = Balances.RowKey
	|union all
	|select Services.Table, Services.LineNumber, presentation ( Services.Item ), presentation ( Services.Item.Unit ),
	|	presentation ( Services.TimeEntry ),
	|	Services.Quantity - Balances.QuantityBalance, Services.Amount - Balances.AmountBalance,
	|	Balances.QuantityBalance, Balances.AmountBalance
	|from Work as Balances
	|	join Services as Services
	|	on Services.TimeEntry = Balances.TimeEntry
	|	and Services.RowKey = Balances.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure Work ( Env, Table ) export
	
	p = Posting.Msg ( Env, "Item, Resource, ResourceBalance, TimeEntry" );
	for each row in Table do
		p.TimeEntry = row.TimeEntry;
		p.Item = row.Item;
		if ( row.QuantityBalance > 0 ) then
			p.Resource = Conversion.NumberToQuantity ( row.QuantityBalance, row.Unit );
			p.ResourceBalance = Conversion.NumberToQuantity ( row.Quantity, row.Unit );
			column = "Quantity";
		elsif ( row.AmountBalance > 0 ) then
			p.Resource = Conversion.NumberToMoney ( row.AmountBalance, Env.Fields.Currency );
			p.ResourceBalance = Conversion.NumberToMoney ( row.Amount, Env.Fields.Currency );
			column = "Amount";
		endif; 
		Output.WorkBalanceError ( p, Output.Row ( row.Table, row.LineNumber, column ), Env.Ref );
	enddo; 

EndProcedure
