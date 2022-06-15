#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Invoice.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		makeItems ( Env );
		if ( Env.SalesOrderExists ) then
			if ( not makeSalesOrders ( Env ) ) then
				return false;
			endif; 
			makeReserves ( Env );
			makeServices ( Env );
		endif;
		if ( Env.TimeEntryExists ) then
			if ( not makeWork ( Env ) ) then
				return false;
			endif; 
		endif;
		if ( not RunDebts.FromInvoice ( Env ) ) then
			return false;
		endif;
	endif;
	prepareSales ( Env );
	ItemDetails.Init ( Env );
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		if ( not makeValues ( Env ) ) then
			return false;
		endif;
	endif;
	if ( not Env.RestoreCost
		and not Env.Realtime ) then
		SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp, Env.UnresolvedItems );
	endif;
	makeSales ( Env );
	ItemDetails.Save ( Env );
	if ( not Env.RestoreCost ) then
		makeDiscounts ( Env );
		commitVAT ( Env );
		commitIncome ( Env );
		attachSequence ( Env );
		if ( not checkBalances ( Env ) ) then
			return false;
		endif; 
		completeShipping ( Env );
	endif;
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	setContext ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	sqlSales ( Env );
	if ( not Env.RestoreCost ) then
		sqlDiscounts ( Env );
		sqlVAT ( Env );
		sqlSequence ( Env );
		sqlShipping ( Env );
		sqlContractAmount ( Env );
		if ( Env.SalesOrderExists ) then
			sqlSalesOrders ( Env );
			sqlReserves ( Env );
			sqlVendorServices ( Env );
		endif;
		if ( Env.TimeEntryExists ) then
			sqlTimeEntries( Env );
		endif;
		sqlQuantity ( Env );
	endif; 
	if ( Env.RestoreCost
		or Env.CostOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
	endif; 
	getTables ( Env );
	fields = Env.Fields;
	if ( not Env.RestoreCost ) then
		amount = Env.ContractAmount;
		fields.Insert ( "Amount", amount.Amount );
		fields.Insert ( "ContractAmount", amount.ContractAmount );
	endif; 
	Env.Insert ( "CheckBalances", Shortage.Check ( fields.Company, Env.Realtime, Env.RestoreCost ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.Department as Department, Documents.PointInTime as Timestamp, Documents.Currency as Currency,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency,
	|	Document.Contract.AdvancesMonthly as AdvancesMonthly";
	if ( not Env.RestoreCost ) then
		s = s + ", Documents.Contract as Contract, Documents.CustomerAccount as CustomerAccount,
		|	Documents.CloseAdvances as CloseAdvances, Documents.Customer as Customer,
		|	case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end as PaymentDate,
		|	Documents.PaymentOption as PaymentOption, PaymentDetails.PaymentKey as PaymentKey,
		|	Documents.Contract.Currency as ContractCurrency,
		|	isnull ( DiscountsBefore.Exists, false ) as DiscountsBeforeDelivery,
		|	isnull ( DiscountsAfter.Exists, false ) as DiscountsAfterDelivery	
		|";
	endif; 
	s = s + "
	|from Document.Invoice as Documents
	|";
	if ( not Env.RestoreCost ) then
		s = s + "
		|	//
		|	// Payment Details
		|	//
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.Option = Documents.PaymentOption
		|	and PaymentDetails.Date = case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end
		|	//
		|	// DiscountsBefore
		|	//
		|	left join (
		|		select top 1 true as Exists
		|		from Document.Invoice.Discounts
		|		where Ref = &Ref
		|		and Detail = undefined
		|		and Document refs Document.SalesOrder
		|	) as DiscountsBefore
		|	on true
		|	//
		|	// DiscountsAfter
		|	//
		|	left join (
		|		select top 1 true as Exists
		|		from Document.Invoice.Discounts
		|		where Ref = &Ref
		|		and ( Detail <> undefined
		|			or not Document refs Document.SalesOrder )
		|	) as DiscountsAfter
		|	on true
		|";
	endif;
	s = s + "
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|;
	|// @SalesOrderExists
	|select top 1 true as Exist
	|from Document.Invoice.Items as Items
	|where Items.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|and Items.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Invoice.Services as Services
	|where Services.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|and Services.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Invoice as Documents
	|where Documents.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|and Documents.Ref = &Ref
	|;
	|// @TimeEntryExists
	|select top 1 true as Exist
	|from Document.Invoice.Items as Items
	|where Items.TimeEntry <> value ( Document.TimeEntry.EmptyRef )
	|and Items.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Invoice.Services as Services
	|where Services.TimeEntry <> value ( Document.TimeEntry.EmptyRef )
	|and Services.Ref = &Ref
	|union
	|select top 1 true
	|from Document.Invoice as Documents
	|where Documents.TimeEntry <> value ( Document.TimeEntry.EmptyRef )
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
	
	Env.Insert ( "SalesOrderExists", Env.SalesOrderExists <> undefined and Env.SalesOrderExists.Exist );
	Env.Insert ( "TimeEntryExists", Env.TimeEntryExists <> undefined and Env.TimeEntryExists.Exist );
	fields = Env.Fields;
	Env.Insert ( "PaymentDiscounts", fields.DiscountsBeforeDelivery or fields.DiscountsAfterDelivery );

EndProcedure

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	fields = Env.Fields;
	foreign = fields.Currency <> fields.LocalCurrency;
	amount = "Amount";
	amountGeneral = "( Total - VAT )";
	if ( foreign ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
		amountGeneral = amountGeneral + rate;
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	list.Insert ( "AmountGeneral", "cast ( " + amountGeneral + " as Number ( 15, 2 ) )" );
	if ( Env.RestoreCost ) then
		return;
	endif;
	vat = "VAT";
	contractVAT = "VAT";
	contractAmount = "( Total - VAT )";
	if ( fields.ContractCurrency <> fields.Currency ) then
		if ( fields.Currency = fields.LocalCurrency ) then
			rate = " / &Rate * &Factor";
		else
			rate = " * &Rate / &Factor";
		endif; 
		contractAmount = contractAmount + rate;
		contractVAT = contractVAT + rate;
	endif; 
	if ( foreign ) then
		rate = " * &Rate / &Factor";
		vat = vat + rate;
	endif;
	list.Insert ( "ContractVAT", "cast ( " + contractVAT + " as Number ( 15, 2 ) )" );
	list.Insert ( "ContractAmount", "cast ( " + contractAmount + " as Number ( 15, 2 ) )" );
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	fields = Env.AmountFields;
	amount = fields.Amount;
	contractAmount = fields.ContractAmount;
	contractVAT = fields.ContractVAT;
	amountGeneral = fields.AmountGeneral;
	usual = not Env.RestoreCost;
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.Price as Price, Items.DiscountRate as DiscountRate,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account, Items.Income as Income, Items.SalesCost as SalesCost,
	|	case when Items.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then Items.Ref.SalesOrder else Items.SalesOrder end as SalesOrder,
	|	case when Items.TimeEntry = value ( Document.TimeEntry.EmptyRef ) then Items.Ref.TimeEntry else Items.TimeEntry end as TimeEntry,
	|	Items.RowKey as RowKey, Items.TimeEntryRow as TimeEntryRow,
	|" + amount + " as Amount";
	if ( usual ) then
		s = s + ", Items.Amount as DocumentAmount, "
		+ contractAmount + " as ContractAmount, "
		+ amountGeneral + " as AmountGeneral, "
		+ contractVAT + " as ContractVAT";
	endif; 
	s = s + "
	|into Items
	|from Document.Invoice.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature
	|;
	|select ""Services"" as Table, Services.LineNumber as LineNumber, Services.Item as Item, Services.Feature as Feature,
	|	Services.Price as Price, Services.Quantity as Quantity, Services.DiscountRate as DiscountRate,
	|	Services.Income as Income, Services.RowKey as RowKey, Services.TimeEntryRow as TimeEntryRow,
	|	case when Services.SalesOrder = value ( Document.SalesOrder.EmptyRef ) then Services.Ref.SalesOrder else Services.SalesOrder end as SalesOrder,
	|	case when Services.TimeEntry = value ( Document.TimeEntry.EmptyRef ) then Services.Ref.TimeEntry else Services.TimeEntry end as TimeEntry,
	|" + amount + " as Amount";
	if ( usual ) then
		s = s + ", Services.Amount as DocumentAmount, "
		+ contractAmount + " as ContractAmount, "
		+ amountGeneral + " as AmountGeneral, "
		+ contractVAT + " as ContractVAT";
	endif; 
	s = s + "
	|into Services
	|from Document.Invoice.Services as Services
	|where Services.Ref = &Ref
	|index by Services.Item, Services.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlSales ( Env )
	
	s = "
	|// ^Sales
	|select value ( Catalog.Warehouses.EmptyRef ) as Warehouse, Services.Item as Item, Services.Feature as Feature,
	|	value ( Catalog.Series.EmptyRef ) as Series, value ( ChartOfAccounts.General.EmptyRef ) as Account,
	|	Services.Income as Income, Services.Quantity as Quantity, Services.Amount as Amount,
	|	Services.ContractAmount as ContractAmount, Services.SalesOrder as SalesOrder, Details.ItemKey as ItemKey,
	|	Services.AmountGeneral as AmountGeneral
	|from Services as Services
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Services.Item
	|	and Details.Package = value ( Catalog.Packages.EmptyRef )
	|	and Details.Feature = Services.Feature
	|	and Details.Series = value ( Catalog.Series.EmptyRef )
	|	and Details.Warehouse = value ( Catalog.Warehouses.EmptyRef )
	|	and Details.Account = value ( ChartOfAccounts.General.EmptyRef )
	|";
	if ( not Env.CostOnline
		and not Env.RestoreCost ) then
		s = s + "
		|union all
		|//
		|// Items sales without cost
		|//
		|select Items.Warehouse, Items.Item, Items.Feature, Items.Series, Items.Account,
		|	Items.Income, Items.Quantity, Items.Amount, Items.ContractAmount, Items.SalesOrder, Details.ItemKey, Items.AmountGeneral
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
	endif; 
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

Procedure sqlShipping ( Env )
	
	s = "
	|select Tasks.Ref as Task, Tasks.RoutePoint as RoutePoint,
	|	cast ( Tasks.BusinessProcess as BusinessProcess.SalesOrder ).SalesOrder as SalesOrder
	|into Tasks
	|from Task.Task as Tasks
	|where not Tasks.DeletionMark
	|and not Tasks.Executed
	|and Tasks.RoutePoint in (
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Shipping ),
	|	value ( BusinessProcess.SalesOrder.RoutePoint.Invoicing ) )
	|;
	|// #Shipping
	|select Tasks.Task as Task, Tasks.RoutePoint as RoutePoint
	|from Tasks as Tasks
	|	//
	|	// SalesOrders
	|	//
	|	join (	select Items.SalesOrder as SalesOrder
	|			from Items as Items
	|			union
	|			select Services.SalesOrder
	|			from Services as Services ) as SalesOrders
	|	on SalesOrders.SalesOrder = Tasks.SalesOrder
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlContractAmount ( Env )
	
	fields = Env.AmountFields;
	s = "
	|// @ContractAmount
	|select sum ( Items.Amount ) as Amount, sum ( Items.ContractAmount ) as ContractAmount,
	|	sum ( Items.ContractVAT ) as ContractVAT
	|from ( select Items.Amount as Amount, Items.ContractAmount as ContractAmount, 0 as ContractVAT
	|		from Items as Items
	|		union all
	|		select Services.Amount, Services.ContractAmount, 0
	|		from Services as Services
	|		union all
	|		select " + fields.VAT + ", " + fields.ContractVAT + ", " + fields.ContractVAT + "
	|		from Document.Invoice as Document
	|		where Document.Ref = &Ref";
	if ( Env.PaymentDiscounts ) then
		s = s + "
		|union all
		|select - Discounts.Amount, - Discounts.ContractAmount, - Discounts.ContractVAT
		|from Discounts as Discounts
		|";
	endif;
	s = s + "
	|) as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlSalesOrders ( Env )
	
	s = "
	|// ^SalesOrders
	|select Items.Item as Item, Items.LineNumber as LineNumber, Items.Table as Table, Items.Feature as Feature,
	|	Items.Quantity as Quantity, Items.DocumentAmount as Amount, Items.SalesOrder as SalesOrder,
	|	Items.RowKey as RowKey, case when ( SalesOrders.Item is null ) then true else false end as InvalidRow
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	left join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.SalesOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Item = Items.Item
	|	and SalesOrders.Feature = Items.Feature
	|	and SalesOrders.Price = Items.Price
	|	and SalesOrders.DiscountRate = Items.DiscountRate
	|	and SalesOrders.Ref.Currency = &Currency
	|where Items.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|union all
	|select Services.Item, Services.LineNumber, Services.Table, Services.Feature, Services.Quantity,
	|	Services.DocumentAmount, Services.SalesOrder, Services.RowKey,
	|	case when ( SalesOrders.Item is null ) then true else false end
	|from Services as Services
	|	//
	|	// SalesOrders
	|	//
	|	left join Document.SalesOrder.Services as SalesOrders
	|	on SalesOrders.Ref = Services.SalesOrder
	|	and SalesOrders.RowKey = Services.RowKey
	|	and SalesOrders.Item = Services.Item
	|	and SalesOrders.Feature = Services.Feature
	|	and ( SalesOrders.Price = Services.Price or Services.Quantity = 0 )
	|	and ( SalesOrders.DiscountRate = Services.DiscountRate or Services.Quantity = 0 )
	|	and SalesOrders.Ref.Currency = &Currency
	|where Services.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReserves ( Env )
	
	s = "
	|select Items.RowKey as RowKey, Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.LineNumber as LineNumber, Items.Quantity as Quantity, Items.SalesOrder as SalesOrder
	|into Reserves
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.SalesOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Reservation <> value ( Enum.Reservation.None )
	|index by Items.RowKey
	|;
	|// ^Reserves
	|select Reserves.Warehouse as Warehouse, Reserves.RowKey as RowKey,
	|	Reserves.Quantity as Quantity, Reserves.SalesOrder as SalesOrder
	|from Reserves as Reserves
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlVendorServices ( Env )
	
	s = "
	|// ^VendorServices
	|select Services.RowKey as RowKey, Services.Quantity as Quantity, Services.SalesOrder as SalesOrder
	|from Services as Services
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Services as SalesOrders
	|	on SalesOrders.Ref = Services.SalesOrder
	|	and SalesOrders.RowKey = Services.RowKey
	|	and SalesOrders.Performer = value ( Enum.Performers.Vendor )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTimeEntries ( Env )
	
	s = "
	|// ^TimeEntries
	|select Items.Item as Item, Items.TimeEntryRow as RowKey, Items.Table as Table,
	|	Items.Quantity as Quantity, 0 as Amount, 0 as HourlyRate, Items.TimeEntry as TimeEntry,
	|	TimeEntries.Ref is null as InvalidRow, Items.LineNumber as LineNumber
	|from Items as Items
	|	//
	|	// TimeEntries
	|	//
	|	left join Document.TimeEntry.Items as TimeEntries
	|	on TimeEntries.Ref = Items.TimeEntry
	|	and TimeEntries.RowKey = Items.TimeEntryRow
	|where Items.TimeEntry <> value ( Document.TimeEntry.EmptyRef )
	|union all
	|select Services.Item, Services.TimeEntryRow, Services.Table, Services.Quantity,
	|	Rates.HourlyRate, Services.Amount, Services.TimeEntry,
	|	TimeEntries.Ref is null or Rates.TimeEntry is null, Services.LineNumber
	|from Services as Services
	|	//
	|	// TimeEntries
	|	//
	|	left join Document.TimeEntry.Tasks as TimeEntries
	|	on TimeEntries.Ref = Services.TimeEntry
	|	and TimeEntries.RowKey = Services.TimeEntryRow
	|	//
	|	// Rates
	|	//
	|	left join InformationRegister.TimeEntryRates as Rates
	|	on Rates.TimeEntry = Services.TimeEntry
	|	and Rates.RowKey = Services.TimeEntryRow
	|	and ( Rates.HourlyRate = Services.Price
	|		or Rates.HourlyRate = 0	)
	|where Services.TimeEntry <> value ( Document.TimeEntry.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlQuantity ( Env )
	
	s = "
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Package as Package, Items.Series as Series, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|";
	if ( Env.SalesOrderExists ) then
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
	|	Items.Capacity as Capacity, Details.ItemKey as ItemKey
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
	|	Items.Package as Package, Items.Item.Unit as Unit, Items.Feature as Feature, Items.Series as Series,
	|	Items.Account as Account, Items.Income as Income, Items.SalesCost as SalesCost, Items.AmountGeneral as AmountGeneral,
	|	Items.QuantityPkg as Quantity, Items.Amount as Amount, Details.ItemKey as ItemKey,
	|	Items.SalesOrder as SalesOrder, Items.ContractAmount as ContractAmount, Items.Capacity as Capacity
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
	q.SetParameter ( "Currency", fields.Currency );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure prepareSales ( Env )
	
	Env.Insert ( "UnresolvedItems", new Array () );
	Env.Insert ( "SalesTable", new ValueTable () );
	table = Env.SalesTable;
	table.Columns.Add ( "Operation", new TypeDescription ( "EnumRef.Operations" ) );
	table.Columns.Add ( "Income", new TypeDescription ( "ChartOfAccountsRef.General" ) );
	table.Columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	table.Columns.Add ( "ContractAmount", new TypeDescription ( "Number" ) );
	
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
	p.Insert ( "DecreasingColumns2", "Amount, ContractAmount, AmountGeneral" );
	p.Insert ( "AddInTable1FromTable2", "Capacity, Income, SalesCost, Warehouse, SalesOrder, AmountGeneral" );
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
	items = Table.Copy ( , "Warehouse, Item, Account, SalesCost, Capacity, Quantity, Cost" );
	items.GroupBy ( "Warehouse, Item, Account, SalesCost, Capacity", "Quantity, Cost" );
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.ItemsRetirement;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	p.Recordset = Env.Registers.General;
	for each row in items do
		p.AccountCr = row.Account;
		p.Amount = row.Cost;
		p.QuantityCr = row.Quantity * row.Capacity;
		p.DimCr1 = row.Item;
		p.DimCr2 = row.Warehouse;
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

Procedure makeItemsSales ( Env, Table )
	
	recordset = Env.Registers.Sales;
	fields = Env.Fields;
	date = fields.Date;
	department = fields.Department;
	customer = fields.Customer;
	sales = Env.SalesTable;
	usual = not Env.RestoreCost;
	for each row in Table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Customer = customer;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
		movement.VAT = row.Amount - row.AmountGeneral;
		movement.Cost = row.Cost;
		movement.SalesOrder = row.SalesOrder;
		if ( usual ) then
			rowSales = sales.Add ();
			rowSales.Operation = Enums.Operations.Sales;
			rowSales.Income = row.Income;
			rowSales.Amount = row.AmountGeneral;
			rowSales.ContractAmount = row.ContractAmount;
		endif; 
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

Procedure makeSales ( Env )

	table = SQL.Fetch ( Env, "$Sales" );
	recordset = Env.Registers.Sales;
	fields = Env.Fields;
	date = fields.Date;
	department = fields.Department;
	customer = fields.Customer;
	sales = Env.SalesTable;
	for each row in table do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, , row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		movement = recordset.Add ();
		movement.Period = date;
		movement.Customer = customer;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
		movement.VAT = row.Amount - row.AmountGeneral;
		movement.SalesOrder = row.SalesOrder;
		if ( not Env.RestoreCost ) then
			rowSales = sales.Add ();
			rowSales.Operation = Enums.Operations.Sales;
			rowSales.Income = row.Income;
			rowSales.Amount = row.AmountGeneral;
			rowSales.ContractAmount = row.ContractAmount;
		endif; 
	enddo; 
	
EndProcedure

Procedure makeDiscounts ( Env )

	if ( not Env.PaymentDiscounts ) then
		return;
	endif;
	fields = Env.Fields;
	date = fields.Date;
	ref = Env.Ref;
	discounts = Env.Registers.Discounts;
	department = fields.Department;
	customer = fields.Customer;
	sales = Env.Registers.Sales;
	salesTable = Env.SalesTable;
	for each row in Env.Discounts do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item );
		endif; 
		movement = discounts.Add ();
		movement.Period = date;
		movement.Amount = row.Total;
		if ( row.BeforeDelivery ) then
			movement.Document = ref;
			movement.Detail = row.Document;
		else
			movement.Document = row.Document;
			movement.Detail = row.Detail;
		endif;
		movement = sales.Add ();
		movement.Period = date;
		movement.Customer = customer;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Amount = - row.Amount;
		movement.VAT = - row.VAT;
		movement.SalesOrder = row.Document;
		rowSales = salesTable.Add ();
		rowSales.Operation = Enums.Operations.SalesDiscount;
		rowSales.Income = row.Income;
		rowSales.Amount = - row.Amount;
		rowSales.ContractAmount = - row.ContractAmount;
	enddo;

EndProcedure

Procedure commitIncome ( Env )
	
	fields = Env.Fields;
	Env.SalesTable.GroupBy ( "Income, Operation", "Amount, ContractAmount" );
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	customerAccount = fields.CustomerAccount;
	customer = fields.Customer;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	for each row in Env.SalesTable do
		p.Operation = row.Operation;
		p.AccountCr = row.Income;
		p.Amount = row.Amount;
		p.AccountDr = customerAccount;
		p.DimDr1 = customer;
		p.DimDr2 = contract;
		p.CurrencyDr = currency;
		p.CurrencyAmountDr = row.ContractAmount;
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
	Env.Insert ( "ItemsExist", table.Count () > 0 );
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

Function makeSalesOrders ( Env )

	recordset = Env.Registers.SalesOrders;
	table = SQL.Fetch ( Env, "$SalesOrders" );
	msg = Posting.Msg ( Env, "DocumentOrder" );
	error = false;
	date = Env.Fields.Date;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			msg.DocumentOrder = row.SalesOrder;
			Output.DocumentOrderItemsNotValid ( msg, Output.Row ( row.Table, row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.SalesOrder = row.SalesOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	return not error;
	
EndFunction

Procedure makeReserves ( Env )

	table = SQL.Fetch ( Env, "$Reserves" );
	Env.Insert ( "ReservesExist", table.Count () > 0 );
	recordset = Env.Registers.Reserves;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.SalesOrder;
		movement.RowKey = row.RowKey;
		movement.Warehouse = row.Warehouse;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeServices ( Env )

	table = SQL.Fetch ( Env, "$VendorServices" );
	Env.Insert ( "VendorServicesExist", table.Count () > 0 );
	recordset = Env.Registers.VendorServices;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.SalesOrder = row.SalesOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function makeWork ( Env )

	recordset = Env.Registers.Work;
	table = SQL.Fetch ( Env, "$TimeEntries" );
	msg = Posting.Msg ( Env, "TimeEntry" );
	error = false;
	date = Env.Fields.Date;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			msg.TimeEntry = row.TimeEntry;
			Output.TimeEntryItemsNotValid ( msg, Output.Row ( row.Table, row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.TimeEntry = row.TimeEntry;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		if ( row.HourlyRate <> 0 ) then
			movement.Amount = row.Amount;
		endif;
	enddo; 
	return not error;
	
EndFunction

Function checkBalances ( Env )
	
	if ( Env.ItemsExist
		and Env.CheckBalances ) then
		Env.Registers.Items.LockForUpdate = true;
		Env.Registers.Items.Write ();
		Shortage.SqlItems ( Env );
	else
		Env.Registers.Items.Write = true;
	endif; 
	if ( Env.SalesOrderExists ) then
		Env.Registers.SalesOrders.LockForUpdate = true;
		Env.Registers.SalesOrders.Write ();
		if ( Env.CheckBalances ) then
			Shortage.SqlSalesOrders ( Env );
			if ( Env.ReservesExist ) then
				Env.Registers.Reserves.LockForUpdate = true;
				Env.Registers.Reserves.Write ();
				Shortage.SqlReserves ( Env );
			else
				Env.Registers.Reserves.Write = true;
			endif;
			if ( Env.VendorServicesExist ) then
				Env.Registers.VendorServices.LockForUpdate = true;
				Env.Registers.VendorServices.Write ();
				Shortage.SqlVendorServices ( Env );
			else
				Env.Registers.VendorServices.Write = true;
			endif; 
		endif; 
	else
		Env.Registers.SalesOrders.Write = true;
		Env.Registers.Reserves.Write = true;
		Env.Registers.VendorServices.Write = true;
	endif; 
	if ( Env.TimeEntryExists ) then
		Env.Registers.Work.LockForUpdate = true;
		Env.Registers.Work.Write ();
		if ( Env.CheckBalances ) then
			Shortage.SqlWork ( Env );
		endif;
	else
		Env.Registers.Work.Write = true;
	endif; 
	if ( Env.Selection.Count () = 0 ) then
		return true;
	endif;
	SQL.Perform ( Env );
	if ( Env.ItemsExist ) then
		table = SQL.Fetch ( Env, "$ShortageItems" );
		if ( table.Count () > 0 ) then
			Shortage.Items ( Env, table );
			return false;
		endif; 
	endif; 
	if ( Env.SalesOrderExists ) then
		table = SQL.Fetch ( Env, "$ShortageSalesOrders" );
		if ( table.Count () > 0 ) then
			Shortage.SalesOrder ( Env, table );
			return false;
		endif; 
		if ( Env.ReservesExist ) then
			table = SQL.Fetch ( Env, "$ShortageReserves" );
			if ( table.Count () > 0 ) then
				Shortage.Reserves ( Env, table );
				return false;
			endif; 
		endif; 
		if ( Env.VendorServicesExist ) then
			table = SQL.Fetch ( Env, "$ShortageVendorServices" );
			if ( table.Count () > 0 ) then
				Shortage.VendorServices ( Env, table );
				return false;
			endif; 
		endif; 
	endif; 
	if ( Env.TimeEntryExists ) then
		table = SQL.Fetch ( Env, "$ShortageWork" );
		if ( table.Count () > 0 ) then
			Shortage.Work ( Env, table );
			return false;
		endif; 
	endif; 
	return true;
	
EndFunction

Procedure completeShipping ( Env )
	
	table = Env.Shipping;
	for each row in table do
		task = row.Task.GetObject ();
		if ( task.CheckExecution () ) then
			task.ExecuteTask ();
		endif; 
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Cost.Write = true;
	registers.Sales.Write = true;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	if ( not Env.RestoreCost ) then
		registers.Debts.Write = true;
		registers.Discounts.Write = true;
		if ( not Env.CheckBalances ) then
			registers.Items.Write = true;
			registers.SalesOrders.Write = true;
			registers.Reserves.Write = true;
			registers.Work.Write = true;
		endif; 
	endif;
	
EndProcedure

Procedure sqlDiscounts ( Env )
	
	if ( not Env.PaymentDiscounts ) then
		return;
	endif;
	vat = "VAT";
	amount = "( Amount - VAT )";
	fields = Env.Fields;
	if ( fields.ContractCurrency <> fields.LocalCurrency ) then
		vat = vat + " * &Rate / &Factor";
		amount = amount + " * &Rate / &Factor";
	endif; 
	s = "
	|select Discounts.LineNumber as LineNumber, Discounts.Document as Document, Discounts.Detail as Detail, Discounts.Item as Item,
	|	Discounts.VATCode as VATCode, Discounts.VATAccount as VATAccount, Discounts.Income as Income,
	|	Details.ItemKey as ItemKey, Discounts.VAT as ContractVAT, Discounts.Amount - Discounts.VAT as ContractAmount,
	|	Discounts.Detail = undefined and Discounts.Document refs Document.SalesOrder as BeforeDelivery,
	|	Discounts.Amount as Total, "
	+ amount + " as Amount,"
	+ vat + " as VAT"
	+ "
	|into Discounts
	|from Document.Invoice.Discounts as Discounts
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Discounts.Item
	|	and Details.Package = value ( Catalog.Packages.EmptyRef )
	|	and Details.Feature = value ( Catalog.Features.EmptyRef )
	|	and Details.Series = value ( Catalog.Series.EmptyRef )
	|	and Details.Warehouse = value ( Catalog.Warehouses.EmptyRef )
	|	and Details.Account = value ( ChartOfAccounts.General.EmptyRef )
	|where Discounts.Ref = &Ref
	|;
	|// #Discounts
	|select * from Discounts
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlVAT ( Env )
	
	amount = Env.AmountFields;
	fields = "VATAccount as Account, " + amount.VAT + " as Amount, " + amount.ContractVAT + " as ContractAmount";
	s = "
	|// #VAT
	|select Taxes.Operation as Operation, Taxes.Account as Account, sum ( Taxes.Amount ) as Amount,
	|	sum ( ContractAmount ) as ContractAmount
	|from (
	|	select value ( Enum.Operations.VATPayable ) as Operation, " + fields + "
	|	from Document.Invoice.Items as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select value ( Enum.Operations.VATPayable ), " + fields + "
	|	from Document.Invoice.Services as Records
	|	where Records.Ref = &Ref
	|";
	if ( Env.PaymentDiscounts ) then
		s = s + "
		|union all
		|select value ( Enum.Operations.VATDiscount ), Discounts.VATAccount, - Discounts.VAT, - Discounts.ContractVAT
		|from Discounts as Discounts
		|";
	endif;
	s = s + "
	|	) as Taxes
	|group by Taxes.Operation, Taxes.Account
	|having sum ( Taxes.Amount ) <> 0
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
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountDr = fields.CustomerAccount;
	p.DimDr1 = fields.Customer;
	p.DimDr2 = fields.Contract;
	p.CurrencyDr = fields.ContractCurrency;
	p.Recordset = Env.Registers.General;
	contractVAT = 0;
	for each row in table do
		operation = row.Operation;
		p.Operation = operation;
		vat = row.ContractAmount;
		p.CurrencyAmountDr = vat;
		p.AccountCr = row.Account;
		p.Amount = row.Amount;
		record = GeneralRecords.Add ( p );
		if ( operation <> Enums.Operations.VATDiscount ) then
			contractVAT = contractVAT + vat;
		endif;
	enddo; 
	amount = Env.ContractAmount;
	if ( contractVAT <> amount.ContractVAT
		and p.DataDr.Fields.Currency ) then
		record.CurrencyAmountDr = record.CurrencyAmountDr + ( amount.ContractVAT - contractVAT );
	endif; 
	
EndProcedure
 
#endregion

#endif