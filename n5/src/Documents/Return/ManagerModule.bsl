#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.IncomingFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.IncomingPresentation ( Metadata.Documents.Return.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	fields = Env.Fields;
	if ( not makeValues ( Env ) ) then
		return false;		
	endif; 
	if ( not RunDebts.FromInvoice ( Env ) ) then
		return false;
	endif;
	makeItems ( Env );
	makeReserves ( Env );
	makeSalesOrder ( Env );
	commitVAT ( Env );
	commitSales ( Env );
	SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	getFields ( Env );
	setContext ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	sqlReserves ( Env );
	sqlWarehouse ( Env );
	sqlSalesOrders ( Env );
	sqlInvoices ( Env );
	sqlInvoicesItems ( Env );
	sqlReturnedItems ( Env );
	sqlItemsAndKeys ( Env );
	sqlInvoicesItemsAndKeys ( Env );
	sqlReturnedItemsAndKeys ( Env );
	sqlInvoicesCost ( Env );
	sqlReturnedCost ( Env );
	sqlCost ( Env );
	sqlVAT ( Env );
	sqlContractAmount ( Env );
	getTables ( Env );
	amount = Env.ContractAmount;
	fields = Env.Fields;
	fields.Insert ( "Amount", amount.Amount );
	fields.Insert ( "ContractAmount", amount.ContractAmount );
	
EndProcedure

Procedure sqlFields ( Env )
	
	paymentDate = "case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end";
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Company as Company,
	|	Documents.Department as Department, Documents.PointInTime as Timestamp, Documents.Currency as Currency,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency,
	|	Documents.Contract.CustomerAdvancesMonthly as AdvancesMonthly, Documents.CloseAdvances as CloseAdvances,
	|	Documents.Contract as Contract, Documents.CustomerAccount as CustomerAccount,
	|	Documents.Customer as Customer, Documents.PaymentOption as PaymentOption,
	|	PaymentDetails.PaymentKey as PaymentKey, " + paymentDate + " as PaymentDate, 
	|	Documents.Contract.Currency as ContractCurrency, Lots.Ref as Lot
	|from Document.Return as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|	//
	|	// Payment Details
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Documents.PaymentOption
	|	and PaymentDetails.Date = " + paymentDate + "
	|where Documents.Ref = &Ref
	|;
	|// @SalesOrderExists
	|select top 1 true as Exist
	|from Document.Return.Items as Items
	|where Items.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|and Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	Env.Insert ( "CostOnline", Options.CostOnline ( Env.Fields.Company ) );
	Env.Insert ( "SalesTable", new ValueTable () );
	table = Env.SalesTable;
	table.Columns.Add ( "Income", new TypeDescription ( "ChartOfAccountsRef.General" ) );
	table.Columns.Add ( "Amount", new TypeDescription ( "Number" ) );
	table.Columns.Add ( "ContractAmount", new TypeDescription ( "Number" ) );
	
EndProcedure 

Procedure setContext ( Env )
	
	Env.Insert ( "SalesOrderExists", Env.SalesOrderExists <> undefined and Env.SalesOrderExists.Exist );

EndProcedure

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	fields = Env.Fields;
	documentCurrency = fields.Currency;
	localCurrency = fields.LocalCurrency;
	amount = "Amount";
	amountGeneral = "( Total - VAT )";
	vat = "VAT";
	total = "Total";
	if ( documentCurrency <> localCurrency ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
		amountGeneral = amountGeneral + rate;
		total = total + rate;
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	list.Insert ( "AmountGeneral", "cast ( " + amountGeneral + " as Number ( 15, 2 ) )" );
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );
	list.Insert ( "Total", "cast ( " + total + " as Number ( 15, 2 ) )" );
	if ( Env.RestoreCost ) then
		return;
	endif;
	contractVAT = "VAT";
	contractAmount = "( Total - VAT )";
	contractTotal = "Total";
	if ( fields.ContractCurrency <> documentCurrency ) then
		if ( documentCurrency = localCurrency ) then
			rate = " / &Rate * &Factor";
		else
			rate = " * &Rate / &Factor";
		endif; 
		contractAmount = contractAmount + rate;
		contractVAT = contractVAT + rate;
		contractTotal = contractTotal + rate;
	endif; 
	list.Insert ( "ContractVAT", "cast ( " + contractVAT + " as Number ( 15, 2 ) )" );
	list.Insert ( "ContractAmount", "cast ( " + contractAmount + " as Number ( 15, 2 ) )" );
	list.Insert ( "ContractTotal", "cast ( " + contractTotal + " as Number ( 15, 2 ) )" );
	
EndProcedure 

Procedure sqlItems ( Env )
	
	fields = Env.AmountFields;
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.Price as Price, Items.DiscountRate as DiscountRate,
	|	case when Items.Item.CountPackages then Items.Capacity else 1 end as Capacity,
	|	case when Items.Item.CountPackages then Items.Package.Description else Items.Item.Unit.Code end as Unit,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account, Items.Income as Income, Items.SalesCost as SalesCost, Items.Invoice as Invoice, Items.SalesOrder as SalesOrder,
	|	Items.RowKey as RowKey, " + fields.Amount + " as Amount, " + fields.ContractAmount + " as ContractAmount, " + fields.AmountGeneral + " as AmountGeneral,
	|	Items.VATAccount as VATAccount, " + fields.VAT + " as VAT, " + fields.ContractVAT + " as ContractVAT, " + fields.ContractTotal + " as ContractTotal
	|into Items
	|from Document.Return.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReserves ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Warehouse as Warehouse, 
	|	Items.SalesOrder as SalesOrder, Items.RowKey as RowKey, Items.Quantity as Quantity
	|into Reserves
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.SalesOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Reservation <> value ( Enum.Reservation.None )
	|;
	|// ^Reserves
	|select Reserves.SalesOrder as DocumentOrder, Reserves.RowKey as RowKey,
	|	Reserves.Warehouse as Warehouse, Reserves.Quantity as Quantity
	|from Reserves as Reserves
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWarehouse ( Env )
	
	s = "
	|// ^Items
	|select Items.Warehouse as Warehouse, Items.Item as Item, Items.Feature as Feature,
	|	Items.Package as Package, Items.Series as Series, sum ( Items.QuantityPkg ) as Quantity
	|from Items as Items
	|where Items.RowKey not in ( select RowKey from Reserves )
	|group by Items.Warehouse, Items.Item, Items.Feature, Items.Package, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlSalesOrders ( Env )
	
	s = "
	|// ^SalesOrders
	|select Items.Item as Item, Items.Feature as Feature, Items.Quantity as Quantity, 
	|	Items.Amount as Amount, Items.SalesOrder as SalesOrder, Items.RowKey as RowKey
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.SalesOrder
	|	and SalesOrders.RowKey = Items.RowKey
	|	and SalesOrders.Item = Items.Item
	|	and SalesOrders.Feature = Items.Feature
	|	and SalesOrders.Price = Items.Price
	|	and SalesOrders.DiscountRate = Items.DiscountRate
	|where Items.SalesOrder <> value ( Document.SalesOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInvoices ( Env )
	
	s = "
	|select distinct Items.Invoice as Invoice
	|into Invoices
	|from Items as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInvoicesItems ( Env )
	
	s = "
	|select Items.Ref as Ref, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account	
	|into InvoicesItems
	|from Document.Invoice.Items as Items
	|where Items.Ref in ( select Invoice from Invoices )
	|index by Items.Item, Items.Feature, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReturnedItems ( Env )
	
	s = "
	|select Items.Ref as Ref, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then Items.Ref.Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account
	|into ReturnedItems
	|from Document.Return.Items as Items
	|where Items.Invoice in ( select Invoice from Invoices )
	|and Items.Ref.Date < &Date
	|index by Items.Item, Items.Feature, Items.Series
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemsAndKeys ( Env )
	
	s = "
	|// ^ItemsAndKeys
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Item.CostMethod as CostMethod, 
	|	Items.Package as Package, Items.Feature as Feature, Items.Series as Series, Items.Warehouse as Warehouse, 
	|	Items.Account as Account, Items.QuantityPkg as Quantity, Items.SalesCost as SalesCost,
	|	Items.Capacity as Capacity, Items.Income as Income, Items.SalesOrder as SalesOrder,
	|	Items.Invoice as Invoice, Items.Amount as Amount, Items.ContractAmount as ContractAmount, 
	|	Items.AmountGeneral as AmountGeneral, Details.ItemKey as ItemKey, Items.Item.Unit as Unit
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

Procedure sqlInvoicesItemsAndKeys ( Env )
	
	s = "
	|select Items.Ref as Ref, Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.Series as Series, 
	|	Items.Warehouse as Warehouse, Items.Account as Account, Details.ItemKey as Itemkey
	|into InvoicesItemsAndKeys
	|from InvoicesItems as Items
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

Procedure sqlReturnedItemsAndKeys ( Env )
	
	s = "
	|select Items.Ref as Ref, Items.Item as Item, Items.Package as Package, Items.Feature as Feature, Items.Series as Series, 
	|	Items.Warehouse as Warehouse, Items.Account as Account, Details.ItemKey as Itemkey
	|into ReturnedItemsAndKeys
	|from ReturnedItems as Items
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

Procedure sqlInvoicesCost ( Env )
	
	s = "
	|select Items.Item as Item, Items.Package as Package, Items.Feature as Feature,
	|	Items.Series as Series, Items.Account as Account, sum ( Cost.Quantity ) as Quantity, 
	|	sum ( Cost.Amount ) as Amount
	|into InvoicesCost
	|from InvoicesItemsAndKeys as Items
	|	//
	|	// Cost
	|	//
	|	join AccumulationRegister.Cost as Cost
	|	on Cost.Recorder = Items.Ref
	|	and Cost.ItemKey = Items.ItemKey
	|group by Items.Item, Items.Package, Items.Feature, Items.Series, Items.Account   
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlReturnedCost ( Env )
	
	s = "
	|select Items.Item as Item, Items.Package as Package, Items.Feature as Feature,
	|	Items.Series as Series, Items.Account as Account, sum ( Cost.Quantity ) as Quantity, 
	|	sum ( Cost.Amount ) as Amount
	|into ReturnedCost
	|from ReturnedItemsAndKeys as Items
	|	//
	|	// Cost
	|	//
	|	join AccumulationRegister.Cost as Cost
	|	on Cost.Recorder = Items.Ref
	|	and Cost.ItemKey = Items.ItemKey
	|group by Items.Item, Items.Package, Items.Feature, Items.Series, Items.Account   
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCost ( Env )
	
	s = "
	|// ^Cost
	|select InvoicesCost.Item as Item, InvoicesCost.Package as Package, InvoicesCost.Feature as Feature, InvoicesCost.Series as Series, 
	|	InvoicesCost.Account as Account, InvoicesCost.Quantity - isnull ( ReturnedCost.Quantity, 0 ) as Quantity,
	|	InvoicesCost.Amount - isnull ( ReturnedCost.Amount, 0 ) as Cost
	|from InvoicesCost as InvoicesCost
	|	//
	|	// ReturnedCost
	|	//
	|	left join ReturnedCost as ReturnedCost
	|	on ReturnedCost.Item = InvoicesCost.Item
	|	and ReturnedCost.Package = InvoicesCost.Package
	|	and ReturnedCost.Feature = InvoicesCost.Feature
	|	and ReturnedCost.Series = InvoicesCost.Series
	|	and ReturnedCost.Account = InvoicesCost.Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlVAT ( Env )
	
	s = "
	|// #VAT
	|select Items.VATAccount as Account, sum ( Items.VAT ) as Amount, sum ( Items.ContractVAT ) as ContractAmount
	|from Items as Items
	|group by Items.VATAccount
	|having sum ( Items.VAT ) > 0
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
	|		select " + fields.VAT + ", " + fields.ContractVAT + ", " + fields.ContractVAT + "
	|		from Document.Return as Document
	|		where Document.Ref = &Ref ) as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Timestamp", ? ( Env.Realtime, undefined, fields.Timestamp ) );
	q.SetParameter ( "Date", fields.Date );
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Perform ( Env );
	
EndProcedure 

Function makeValues ( Env )
	
	cost = undefined;
	if ( not calcCost ( Env, cost ) ) then
		return false;		
	endif;
	makeLot ( Env );
	makeCost ( Env, cost );
	makeExpenses ( Env, cost );
	makeSales ( Env, cost );
	commitCost ( Env, cost );
	setCostBound ( Env );
	return true;
	
EndFunction

Function calcCost ( Env, Cost )
	
	items = SQL.Fetch ( Env, "$ItemsAndKeys" );
	Cost = getCost ( Env, items );
	error = ( items.Count () > 0 );
	if ( error ) then
		completeCost ( Env, Cost, items );
		return false;
	endif; 
	return true;
	
EndFunction

Function getCost ( Env, Items )
	
	cost = SQL.Fetch ( Env, "$Cost" );
	p = new Structure ();
	p.Insert ( "FilterColumns", "Item, Package, Feature, Series, Account" );
	p.Insert ( "KeyColumn", "Quantity" );
	p.Insert ( "KeyColumnAvailable", "QuantityBalance" );
	p.Insert ( "DecreasingColumns", "Cost" );
	p.Insert ( "AddInTable1FromTable2", "ItemKey, Invoice, Warehouse, Capacity, SalesCost, CostMethod, Amount, AmountGeneral, ContractAmount, Income, SalesOrder" );
	return CollectionsSrv.Decrease ( cost, Items, p );
	
EndFunction

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

Procedure makeLot ( Env )
	
	fields = Env.Fields;
	if ( fields.Lot = null ) then
		obj = Catalogs.Lots.CreateItem ();
		obj.Date = Env.Fields.Date;
		obj.Document = Env.Ref;
		obj.Write ();
		fields.Lot = obj.Ref;
	endif;
	
EndProcedure

Procedure makeCost ( Env, Table )
	
	recordset = Env.Registers.Cost;
	items = Table.Copy ( , "ItemKey, Item, Package, Feature, Series, Warehouse, Account, CostMethod, Quantity, Cost" );
	items.GroupBy ( "ItemKey, Item, Package, Feature, Series, Warehouse, Account, CostMethod", "Quantity, Cost" );
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	fifo = Enums.Cost.FIFO;
	ItemDetails.Init ( Env );
	for each row in items do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif;
		movement.ItemKey = row.ItemKey;
		if ( row.CostMethod = fifo ) then
			movement.Lot = lot;
		endif; 
		movement.Quantity = row.Quantity;
		movement.Amount = row.Cost;
	enddo;
	ItemDetails.Save ( Env );
	
EndProcedure

Procedure makeExpenses ( Env, Table )
	
	recordset = Env.Registers.Expenses;
	expenses = Table.Copy ( , "ItemKey, Invoice, SalesCost, Quantity, Cost" );
	expenses.GroupBy ( "ItemKey, Invoice, SalesCost", "Quantity, Cost" );
	date = Env.Fields.Date;
	for each row in expenses do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Document = row.Invoice;
		movement.ItemKey = row.ItemKey;
		movement.Account = row.SalesCost;
		movement.AmountDr = - row.Cost;
		movement.QuantityDr = - row.Quantity;
	enddo;
	
EndProcedure

Procedure makeSales ( Env, Table )
	
	recordset = Env.Registers.Sales;
	items = Table.Copy ( , "ItemKey, Income, Item, SalesOrder, Quantity, Amount, Cost, AmountGeneral, ContractAmount" );
	items.GroupBy ( "ItemKey, Income, Item, SalesOrder", "Quantity, Amount, Cost, AmountGeneral, ContractAmount" );
	fields = Env.Fields;
	date = fields.Date;
	department = fields.Department;
	customer = fields.Customer;
	sales = Env.SalesTable;
	usual = not Env.RestoreCost;
	for each row in items do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Customer = customer;
		movement.ItemKey = row.ItemKey;
		movement.Department = department;
		movement.Account = row.Income;
		movement.Quantity = - row.Quantity;
		movement.Amount = - row.Amount;
		movement.VAT = - ( row.Amount - row.AmountGeneral );
		movement.Cost = - row.Cost;
		movement.SalesOrder = row.SalesOrder;
		if ( usual ) then
			rowSales = sales.Add ();
			rowSales.Income = row.Income;
			rowSales.Amount = - row.AmountGeneral;
			rowSales.ContractAmount = - row.ContractAmount;
		endif;
	enddo; 
	
EndProcedure

Procedure commitCost ( Env, Table )
	
	fields = Env.Fields;
	items = Table.Copy ( , "Account, Item, Capacity, Warehouse, SalesCost, Quantity, Cost" );
	items.GroupBy ( "Account, Item, Capacity, Warehouse, SalesCost", "Quantity, Cost" );
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.ItemsReturn;
	p.DimCr1Type = "Items";
	p.DimCr2Type = "Warehouses";
	for each row in items do
		p.AccountCr = Row.Account;
		p.Amount = - Row.Cost;
		p.QuantityCr = - Row.Quantity * Row.Capacity;
		p.DimCr1 = Row.Item;
		p.DimCr2 = Row.Warehouse;
		p.AccountDr = Row.SalesCost;
		p.Recordset = Env.Registers.General;
		GeneralRecords.Add ( p );		
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

Procedure makeItems ( Env )

	table = SQL.Fetch ( Env, "$Items" );
	recordset = Env.Registers.Items;
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

Procedure makeReserves ( Env )

	table = SQL.Fetch ( Env, "$Reserves" );
	recordset = Env.Registers.Reserves;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.RowKey;
		movement.Warehouse = row.Warehouse;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeSalesOrder ( Env )
	
	recordset = Env.Registers.SalesOrders;
	table = SQL.Fetch ( Env, "$SalesOrders" );
	date = Env.Fields.Date;
	for each row in table do 
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.SalesOrder = row.SalesOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo;
	
EndProcedure

Procedure commitVAT ( Env )
	
	table = Env.VAT;
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountDr = fields.CustomerAccount;
	p.DimDr1 = fields.Customer;
	p.DimDr2 = fields.Contract;
	p.CurrencyDr = fields.ContractCurrency;
	p.Operation = Enums.Operations.VATPayable;
	p.Recordset = Env.Registers.General;
	for each row in table do
		p.AccountCr = row.Account;
		p.CurrencyAmountDr = - row.ContractAmount;
		p.Amount = - row.Amount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure commitSales ( Env )
	
	fields = Env.Fields;
	Env.SalesTable.GroupBy ( "Income", "Amount, ContractAmount" );
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.Sales;
	p.Recordset = Env.Registers.General;
	customerAccount = fields.CustomerAccount;
	customer = fields.Customer;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	for each row in Env.SalesTable do
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

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.Items.Write = true;
	registers.Reserves.Write = true;
	registers.Debts.Write = true;
	registers.SalesOrders.Write = true;
	registers.Cost.Write = true;
	registers.Expenses.Write = true;
	registers.Sales.Write = true;
	registers.General.Write = true;
	
EndProcedure

#endregion

#endif