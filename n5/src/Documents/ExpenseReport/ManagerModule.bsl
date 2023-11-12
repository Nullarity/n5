#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.ExpenseReport.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	if ( not getData ( Env ) ) then
		return false;
	endif; 
	if ( not checkRows ( Env ) ) then
		return false;
	endif; 
	makeValues ( Env );
	makeItems ( Env );
	makeFixedAssets ( Env );
	makeIntangibleAssets ( Env );
	makeAccounts ( Env );
	commitVAT ( Env );
	makeInternalOrders ( Env );
	makeReserves ( Env );
	makeVendorServices ( Env );
	makeAllocations ( Env );
	makeProducerPrices ( Env );
	fields = Env.Fields;
	SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	if ( not checkBalances ( Env ) ) then
		return false;
	endif; 
	completeDelivery ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Function getData ( Env )
	
	sqlFields ( Env );
	getFields ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	sqlFixedAssets ( Env );
	sqlIntangibleAssets ( Env );
	sqlAccounts ( Env );
	sqlVAT ( Env );
	sqlInvalidRows ( Env );
	if ( Options.Series () ) then
		sqlEmptySeries ( Env );
	endif;
	sqlCost ( Env );
	sqlWarehouse ( Env );
	sqlInternalOrders ( Env );
	sqlReserves ( Env );
	sqlVendorServices ( Env );
	sqlExpenses ( Env );
	sqlAllocation ( Env );
	sqlDelivery ( Env );
	sqlProducerPrices ( Env );
	getTables ( Env );
	return true;
	
EndFunction

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Documents.Date as Date, Documents.Warehouse as Warehouse, Documents.Employee as Employee, Documents.Company as Company, 
	|	Documents.Currency as Currency, Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency, 
	|	Documents.PointInTime as Timestamp, Documents.EmployeeAccount as EmployeeAccount, Lots.Ref as Lot
	|from Document.ExpenseReport as Documents
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
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	fields = Env.Fields;
	foreign = fields.Currency <> fields.LocalCurrency;
	amount = "( Total - VAT )";
	if ( foreign ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	if ( Env.RestoreCost ) then
		return;
	endif;
	vat = "VAT";
	if ( foreign ) then
		vat = vat + rate;
	endif;
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );

EndProcedure 

Procedure sqlItems ( Env )
	
	amount = Env.AmountFields.Amount;
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.DiscountRate as DiscountRate,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse, Items.RowKey as RowKey,
	|	Items.Account as Account, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.Social as Social, Items.Price as Price, Items.ProducerPrice as ProducerPrice,
	|	" + amount + " as Amount, Items.Amount as CurrencyAmount
	|into Items
	|from Document.ExpenseReport.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series, Items.RowKey, Items.DocumentOrder, Items.DocumentOrderRowKey
	|;
	|select ""Services"" as Table, Services.LineNumber as LineNumber, Services.Item as Item, Services.Feature as Feature,
	|	Services.RowKey as RowKey, Services.Quantity as Quantity, Services.DiscountRate as DiscountRate,
	|	Services.Account as Account, Services.Expense as Expense, Services.Department as Department, Services.Product as Product,
	|	Services.ProductFeature as ProductFeature, Services.DocumentOrder as DocumentOrder, Services.DocumentOrderRowKey as DocumentOrderRowKey,
	|	" + amount + " as Amount, Services.Amount as CurrencyAmount
	|into Services
	|from Document.ExpenseReport.Services as Services
	|where Services.Ref = &Ref
	|index by Services.Item, Services.Feature, Services.RowKey, Services.DocumentOrder, Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlFixedAssets ( Env )
	
	s = "
	|select Items.Acceleration as Acceleration, Items.Charge as Charge,
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.LiquidationValue as LiquidationValue, Items.Method as Method, 
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.Schedule as Schedule, Items.UsefulLife as UsefulLife,
	|	" + Env.AmountFields.Amount + " as Amount, Items.Amount as CurrencyAmount
	|into FixedAssets
	|from Document.ExpenseReport.FixedAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #FixedAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.LiquidationValue as LiquidationValue, Items.Method as Method, 
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.Schedule as Schedule, Items.UsefulLife as UsefulLife,
	|	Items.Amount as Amount, Items.CurrencyAmount as CurrencyAmount
	|from FixedAssets as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlIntangibleAssets ( Env )
	
	s = "
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.Method as Method, Items.Item.Account as Account, Items.Starting as Starting,
	|	Items.UsefulLife as UsefulLife, " + Env.AmountFields.Amount + " as Amount, Items.Amount as CurrencyAmount
	|into IntangibleAssets
	|from Document.ExpenseReport.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #IntangibleAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.Method as Method, Items.Item.Account as Account, Items.Starting as Starting,
	|	Items.UsefulLife as UsefulLife, Items.Amount as Amount, Items.CurrencyAmount as CurrencyAmount
	|from IntangibleAssets as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAccounts ( Env )
	
	s = "
	|// #Accounts
	|select Accounts.Account as Account, Accounts.Content as Content, Accounts.Currency as Currency,
	|	Accounts.CurrencyAmount as CurrencyAmount, Accounts.Rate as Rate, Accounts.Factor as Factor,
	|	Accounts.Quantity as Quantity, Accounts.Dim1 as Dim1, Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3,
	|	" + Env.AmountFields.Amount + " as Amount, Accounts.Amount as CurrencyAmountCr
	|from Document.ExpenseReport.Accounts as Accounts
	|where Accounts.Ref = &Ref
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
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlEmptySeries ( Env )
	
	s = "
	|// ^EmptySeries
	|select Items.LineNumber as LineNumber
	|from Items as Items
	|where Items.Item.Series
	|and Items.Series = value ( Catalog.Series.EmptyRef )
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlCost ( Env )
	
	s = "
	|// ^Cost
	|select Items.Item as Item, Items.Item.CostMethod as CostMethod, Items.Package as Package, Items.Feature as Feature,
	|	Items.Series as Series, Items.Warehouse as Warehouse, Items.Account as Account, Details.ItemKey as Itemkey,
	|	Items.QuantityPkg as Quantity, Items.Quantity as Units, Items.Amount as Amount, Items.CurrencyAmount as CurrencyAmount
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
	|	on InternalOrder.Ref = DocServices.DocumentOrder
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
 
Procedure sqlVendorServices ( Env )
	
	s = "
	|// ^VendorServices
	|select Services.DocumentOrder as SalesOrder, Services.DocumentOrderRowKey as RowKey, Services.Quantity as Quantity
	|from Services as Services
	|where Services.DocumentOrder refs Document.SalesOrder
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlExpenses ( Env )
	
	s = "
	|// ^Expenses
	|select Services.Item as Item, Services.Feature as Feature, Services.Account as Account, Services.Expense as Expense,
	|	Services.Department as Department, Services.Product as Product, Services.ProductFeature as ProductFeature,
	|	sum ( Services.Quantity ) as Quantity, sum ( Services.Amount ) as Amount, Details.ItemKey as Itemkey, sum ( Services.CurrencyAmount ) as CurrencyAmount
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
	|	Services.Product, Services.ProductFeature, Details.ItemKey
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

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Warehouse", fields.Warehouse );
	q.SetParameter ( "Timestamp", fields.Timestamp );
	q.SetParameter ( "Rate", fields.Rate );
	q.SetParameter ( "Factor", fields.Factor );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Function checkRows ( Env )
	
	ok = true;
	table = SQL.Fetch ( Env, "$InvalidRows" );
	ref = Env.Ref;
	for each row in table do
		Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( row.Table, row.LineNumber, "Item" ), ref );
		ok = false;
	enddo; 
	if ( Options.Series () ) then
		table = SQL.Fetch ( Env, "$EmptySeries" );
		for each row in table do
			Output.UndefinedSeries ( , Output.Row ( "Items", row.LineNumber, "Series" ), Env.Ref );
			ok = false;
		enddo; 
	endif;
	return ok;
	
EndFunction

Procedure makeValues ( Env )

	ItemDetails.Init ( Env );
	table = SQL.Fetch ( Env, "$Cost" );
	makeCost ( Env, table );
	table = SQL.Fetch ( Env, "$Expenses" );
	makeExpenses ( Env, table );
	commitExpenses ( Env, table );
	ItemDetails.Save ( Env );
	
EndProcedure

Procedure makeCost ( Env, Table )
	
	p = GeneralRecords.GetParams ();
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	fifo = Enums.Cost.FIFO;
	for each row in Table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
		movement.ItemKey = row.ItemKey;
		if ( row.CostMethod = fifo ) then
			if ( lot = null ) then
				lot = newLot ( Env );
				fields.Lot = lot;
			endif; 
			movement.Lot = lot;
		endif; 
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
		commitCost ( Env, p, row );
	enddo; 
	
EndProcedure

Function newLot ( Env )
	
	obj = Catalogs.Lots.CreateItem ();
	obj.Date = Env.Fields.Date;
	obj.Document = Env.Ref;
	obj.Write ();
	return obj.Ref;
	
EndFunction

Procedure commitCost ( Env, Params, Row )
	
	fields = Env.Fields;
	Params.Date = fields.Date;
	Params.Company = fields.Company;
	Params.AccountDr = row.Account;
	Params.AccountCr = fields.EmployeeAccount;
	Params.Operation = Enums.Operations.ItemsReceipt;
	Params.Amount = row.Amount;
	Params.QuantityDr = row.Units;
	Params.DimDr1 = row.Item;
	Params.DimDr2 = row.Warehouse;
	Params.DimCr1 = fields.Employee;
	Params.CurrencyCr = fields.Currency;
	Params.CurrencyAmountCr = row.CurrencyAmount;
	Params.Recordset = Env.Registers.General;
	GeneralRecords.Add ( Params );

EndProcedure

Procedure makeExpenses ( Env, Table )

	date = Env.Fields.Date;
	recordset = Env.Registers.Expenses;
	ref = Env.Ref;
	for each row in Table do
		movement = recordset.Add ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, , row.Feature );
		endif; 
		movement.Document = ref;
		movement.ItemKey = row.ItemKey;
		movement.Account = row.Account;
		movement.Expense = row.Expense;
		movement.Department = row.Department;
		movement.Product = row.Product;
		movement.ProductFeature = row.ProductFeature;
		movement.QuantityDr = row.Quantity;
		movement.AmountDr = row.Amount;
	enddo; 
	
EndProcedure

Procedure commitExpenses ( Env, Table )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.ExpenseReceipt;
	p.Recordset = Env.Registers.General;
	employeeAccount = fields.EmployeeAccount;
	employee = fields.Employee;
	currency = fields.Currency;
	for each row in table do
		p.AccountDr = row.Account;
		p.AccountCr = employeeAccount;
		p.Amount = row.Amount;
		p.QuantityDr = row.Quantity;
		p.DimDr1 = row.Expense;
		p.DimDr2 = row.Department;
		p.DimCr1 = employee;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo; 

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

Procedure makeFixedAssets ( Env )

	table = Env.FixedAssets;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	registers = Env.Registers;
	depreciation = registers.Depreciation;
	location = registers.FixedAssetsLocation;
	fields = Env.Fields;
	date = fields.Date;
	startDepreciation = BegOfMonth ( AddMonth ( date, 1 ) );
	employeeAccount = fields.EmployeeAccount;
	employee = fields.Employee;
	currency = fields.Currency;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		item = row.Item;
		movementDepreciation = depreciation.Add ();
		movementDepreciation.Period = startDepreciation;
		movementDepreciation.Asset = item;
		movementDepreciation.Acceleration = row.Acceleration;
		movementDepreciation.Charge = row.Charge;
		movementDepreciation.Expenses = row.Expenses;
		movementDepreciation.LiquidationValue = row.LiquidationValue;
		movementDepreciation.Method = row.Method;
		movementDepreciation.Starting = row.Starting;
		movementDepreciation.Schedule = row.Schedule;
		movementDepreciation.UsefulLife = row.UsefulLife;
		movementLocation = location.Add ();
		movementLocation.Period = date;
		movementLocation.Asset = item;
		movementLocation.Employee = row.Employee;
		movementLocation.Department = row.Department;
		p.AccountDr = row.Account;
		p.QuantityDr = 1;
		p.Amount = row.Amount;
		p.DimDr1 = item;
		p.AccountCr = employeeAccount;
		p.DimCr1 = employee;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure makeIntangibleAssets ( Env )

	table = Env.IntangibleAssets;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	registers = Env.Registers;
	amortization = registers.Amortization;
	location = registers.IntangibleAssetsLocation;
	fields = Env.Fields;
	date = fields.Date;
	employeeAccount = fields.EmployeeAccount;
	employee = fields.Employee;
	currency = fields.Currency;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		item = row.Item;
		movementAmortization = amortization.Add ();
		movementAmortization.Period = date;
		movementAmortization.Asset = item;
		movementAmortization.Acceleration = row.Acceleration;
		movementAmortization.Charge = row.Charge;
		movementAmortization.Expenses = row.Expenses;
		movementAmortization.Method = row.Method;
		movementAmortization.Starting = row.Starting;
		movementAmortization.UsefulLife = row.UsefulLife;
		movementLocation = location.Add ();
		movementLocation.Period = date;
		movementLocation.Asset = item;
		movementLocation.Employee = row.Employee;
		movementLocation.Department = row.Department;
		p.AccountDr = row.Account;
		p.QuantityDr = 1;
		p.Amount = row.Amount;
		p.DimDr1 = item;
		p.AccountCr = employeeAccount;
		p.DimCr1 = employee;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Procedure makeAccounts ( Env )
	
	table = Env.Accounts;
	if ( table.Count () = 0 ) then
		return;
	endif; 
	fields = Env.Fields;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.OtherReceipt;
	p.Recordset = Env.Registers.General;
	employeeAccount = fields.EmployeeAccount;
	employee = fields.Employee;
	currency = fields.Currency;
	for each row in table do
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		p.QuantityDr = row.Quantity;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
		p.CurrencyDr = row.Currency;
		p.CurrencyAmountDr = row.CurrencyAmount;
		p.AccountCr = employeeAccount;
		p.DimCr1 = employee;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.CurrencyAmountCr;
		GeneralRecords.Add ( p );
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

Procedure makeVendorServices ( Env )

	recordset = Env.Registers.VendorServices;
	table = SQL.Fetch ( Env, "$VendorServices" );
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.SalesOrder = row.SalesOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeAllocations ( Env )
	
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
	return true;
		
EndFunction

Procedure completeDelivery ( Env )
	
	table = Env.Delivery;
	for each row in table do
		task = row.Task.GetObject ();
		if ( task.CheckExecution () ) then
			task.ExecuteTask ();
		endif; 
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	registers.Items.Write = true;
	registers.Cost.Write = true;
	registers.Reserves.Write = true;
	registers.VendorServices.Write = true;
	registers.ItemExpenses.Write = true;
	registers.Amortization.Write = true;
	registers.Depreciation.Write = true;
	registers.FixedAssetsLocation.Write = true;
	registers.IntangibleAssetsLocation.Write = true;
	registers.ProducerPrices.Write = true;
	
EndProcedure

Procedure sqlVAT ( Env )
	
	fields = "VATAccount as Account, " + Env.AmountFields.VAT + " as Amount, VAT as CurrencyAmount";
	s = "
	|// #VAT
	|select Taxes.Account as Account, sum ( Taxes.Amount ) as Amount, sum ( Taxes.CurrencyAmount ) as CurrencyAmount
	|from (
	|	select " + fields + "
	|	from Document.ExpenseReport.Items as Records
	|	where Records.Ref = &Ref
	|	and Records.Type = value ( Enum.DocumentTypes.Invoice )
	|	union all
	|	select " + fields + "
	|	from Document.ExpenseReport.Services as Records
	|	where Records.Ref = &Ref
	|	and Records.Type = value ( Enum.DocumentTypes.Invoice )
	|	union all
	|	select " + fields + "
	|	from Document.ExpenseReport.FixedAssets as Records
	|	where Records.Ref = &Ref
	|	and Records.Type = value ( Enum.DocumentTypes.Invoice )
	|	union all
	|	select " + fields + "
	|	from Document.ExpenseReport.IntangibleAssets as Records
	|	where Records.Ref = &Ref
	|	and Records.Type = value ( Enum.DocumentTypes.Invoice )
	|	union all
	|	select " + fields + "
	|	from Document.ExpenseReport.Accounts as Records
	|	where Records.Ref = &Ref
	|	and Records.Type = value ( Enum.DocumentTypes.Invoice )
	|	) as Taxes
	|group by Taxes.Account
	|having sum ( Taxes.Amount ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProducerPrices ( Env )
	
	s = "
	|// #ProducerPrices
	|select Items.Item as Item, Items.ProducerPrice as Price, Items.Package as Package, Items.Feature as Feature
	|from Items as Items
	|where Items.Social
	|and Items.Price <> 0
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
	p.AccountCr = fields.EmployeeAccount;
	p.DimCr1 = fields.Employee;
	p.CurrencyCr = fields.Currency;
	p.Operation = Enums.Operations.VATReceivable;
	p.Recordset = Env.Registers.General;
	for each row in table do
		p.CurrencyAmountCr = row.CurrencyAmount;
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		GeneralRecords.Add ( p );
	enddo;
	
EndProcedure

Procedure makeProducerPrices ( Env ) 

	table = Env.ProducerPrices;
	if ( table.Count () = 0 ) then
		return;
	endif;
	recordset = Env.Registers.ProducerPrices;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.Add ();
		movement.Period = date;
		movement.Item = row.Item;
		movement.Package = row.Package;
		movement.Feature = row.Feature;
		movement.Price = row.Price;
	enddo;

EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	Print.SetFooter ( Params.TabDoc );
	setPageSettings ( Params );
	getPrintData ( Params, Env );
	putHeader ( Params, Env );
	putTables ( Params, Env );
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
	|select Documents.Number as Number, Documents.Date as Date, Documents.Company.FullDescription as Company,
	|	presentation ( Documents.Employee ) as Employee, presentation ( Documents.Currency ) as Currency
	|from Document.ExpenseReport as Documents
	|where Documents.Ref = &Ref
	|;
	|// #Items
	|select presentation ( Items.Item ) as Item,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
	|	Items.QuantityPkg as Quantity, Items.LineNumber as Line, Items.Amount as Amount, Items.Item.Code as Code, 1 as Sort
	|from Document.ExpenseReport.Items as Items
	|where Items.Ref = &Ref
	|union all
	|select presentation ( Items.Item ), Items.Item.Unit.Code, Items.Quantity, Items.LineNumber, Items.Amount, Items.Item.Code, 2
	|from Document.ExpenseReport.Services as Items
	|where Items.Ref = &Ref
	|union all
	|select presentation ( Items.Item ), Items.Item.Unit.Code, 1, Items.LineNumber, Items.Amount, Items.Item.Code, 3
	|from Document.ExpenseReport.FixedAssets as Items
	|where Items.Ref = &Ref
	|union all
	|select presentation ( Items.Item ), Items.Item.Unit.Code, 1, Items.LineNumber, Items.Amount, Items.Item.Code, 4
	|from Document.ExpenseReport.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|order by Sort, Items.LineNumber
	|;
	|// #Accounts
	|select presentation ( Accounts.Account ) as Account, presentation ( Accounts.Dim1 ) as Dim1, presentation ( Accounts.Dim2 ) as Dim2, 
	|	presentation ( Accounts.Dim3 ) as Dim3, Accounts.LineNumber as Line, Accounts.Amount as Amount, Accounts.Quantity as Quantity
	|from Document.ExpenseReport.Accounts as Accounts
	|where Accounts.Ref = &Ref
	|order by Accounts.LineNumber
	|;
	|// #Payments
	|select presentation ( Documents.Ref ) as Document, presentation ( Documents.Vendor ) as Vendor, presentation ( Documents.Contract ) as Contract, 
	|	Documents.Total as Amount
	|from Document.VendorPayment as Documents
	|where Documents.Posted
	|and Documents.ExpenseReport = &Ref
	|order by Documents.Date, Documents.Vendor.Description
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putHeader ( Params, Env )
	
	area = Env.T.GetArea ( "Header" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure putTables ( Params, Env ) 

	Env.Insert ( "Accuracy", Application.Accuracy () );
	putTable ( Params, Env, "Items" );
	putTable ( Params, Env, "Accounts" );
	putTable ( Params, Env, "Payments" );

EndProcedure

Procedure putTable ( Params, Env, Table )
	
	items = Env [ Table ];
	if ( items.Count () = 0 ) then
		return;
	endif;
	t = Env.T;
	tabDoc = Params.TabDoc;
	tabDoc.Put ( t.GetArea ( "Table" + Table ) );
	Print.Repeat ( tabDoc );
	area = t.GetArea ( "Row" + Table );
	p = area.Parameters;
	line = 1;
	amount = 0;
	useQuantity = items.Columns.Find ( "Quantity" ) <> undefined;
	accuracy = Env.Accuracy;
	for each row in items do
		p.Fill ( row );
		p.Line = line;
		if ( useQuantity ) then
			p.Quantity = Format ( row.Quantity, accuracy );
		endif;
		line = line;
		tabDoc.Put ( area );
		line = line + 1;
		amount = amount + row.Amount;
	enddo;
	area = t.GetArea ( "Totals" );
	area.Parameters.Amount = amount;
	tabDoc.Put ( area );
	
EndProcedure

#endregion


#endif
