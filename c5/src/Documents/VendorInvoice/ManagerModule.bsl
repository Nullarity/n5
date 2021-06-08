#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.IncomingFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.IncomingPresentation ( Metadata.Documents.VendorInvoice.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	if ( not getData ( Env ) ) then
		return false;
	endif; 
	fields = Env.Fields;
	if ( fields.Forms
		and not RunRanges.Check ( Env ) ) then
		return false;
	endif;
	if ( invalidRows ( Env ) ) then
		return false;
	endif; 
	if ( not applyDiscount ( Env ) ) then
		return false;
	endif;
	makeValues ( Env );
	if ( not distributeExpenses ( Env ) ) then
		return false;
	endif; 
	makeItems ( Env );
	makeFixedAssets ( Env );
	makeIntangibleAssets ( Env );
	makeAccounts ( Env );
	makeDiscounts ( Env );
	commitVAT ( Env );
	makeInternalOrders ( Env );
	makeReserves ( Env );
	makeVendorServices ( Env );
	makePurchaseOrders ( Env );
	makeAllocations ( Env );
	makeProvision ( Env );
	makeProducerPrices ( Env );
	if ( not RunDebts.FromInvoice ( Env ) ) then
		return false;
	endif;
	SequenceCost.Rollback ( Env.Ref, fields.Company, fields.Timestamp );
	if ( fields.Forms
		and not RunRanges.MakeReceipt ( Env ) ) then
		return false;
	endif;
	if ( not checkBalances ( Env ) ) then
		return false;
	endif; 
	writeDistribution ( Env );
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
	defineAmount ( Env );
	sqlItems ( Env );
	sqlFixedAssets ( Env );
	sqlIntangibleAssets ( Env );
	sqlAccounts ( Env );
	sqlDiscounts ( Env );
	sqlReserves ( Env );
	sqlVAT ( Env );
	sqlContractAmount ( Env );
	sqlInvalidRows ( Env );
	sqlCost ( Env );
	sqlWarehouse ( Env );
	sqlInternalOrders ( Env );
	sqlVendorServices ( Env );
	sqlExpenses ( Env );
	fields = Env.Fields;
	if ( fields.Forms ) then
		RunRanges.SqlData ( Env );
	endif;
	if ( fields.DistributionExists ) then
		sqlDistributingExpenses ( Env );
	endif; 
	if ( Env.PurchaseOrderExists ) then
		sqlPurchaseOrders ( Env );
		sqlProvision ( Env );
	endif;
	sqlAllocation ( Env );
	sqlDelivery ( Env );
	sqlProducerPrices ( Env );
	getTables ( Env );
	amount = Env.ContractAmount;
	fields.Insert ( "Amount", amount.Amount );
	fields.Insert ( "ContractAmount", amount.ContractAmount );
	return true;
	
EndFunction

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select top 1 Documents.Warehouse as Warehouse, Documents.Vendor as Vendor, Documents.ContractAmount as ContractAmount,
	|	Documents.Company as Company, Documents.Contract as Contract, Documents.Currency as Currency, Documents.Contract.Currency as ContractCurrency,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency, Constants.AdvancesMonthly as AdvancesMonthly,
	|	Documents.PointInTime as Timestamp, Documents.VendorAccount as VendorAccount, Lots.Ref as Lot, Documents.CloseAdvances as CloseAdvances,
	|	case
	|		when Documents.ExpensesPeriod = datetime ( 1, 1, 1 )
	|			or beginofperiod ( Documents.ExpensesPeriod, month ) = beginofperiod ( Documents.Date, month ) then
	|			Documents.Date
	|		else
	|			endofperiod ( Documents.ExpensesPeriod, month )
	|	end as date,
	|	case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end as PaymentDate,
	|	Documents.PaymentOption as PaymentOption, PaymentDetails.PaymentKey as PaymentKey, Documents.Import as Import,
	|	isnull ( Distribution.Exist, false ) as DistributionExists, isnull ( Forms.Exists, false ) as Forms,
	|	isnull ( PaymentDiscounts.Amount, 0 ) as PaymentDiscount, Documents.DiscountAccount as DiscountAccount
	|from Document.VendorInvoice as Documents
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = &Ref
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Documents.PaymentOption
	|	and PaymentDetails.Date = case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end
	|	//
	|	// Payment discounts
	|	//
	|	left join ( select sum ( Amount ) from Document.VendorInvoice.Discounts where Ref = &Ref ) as PaymentDiscounts
	|	on true
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|	//
	|	// Distribution
	|	//
	|	left join ( select top 1 true as Exist
	|			from Document.VendorInvoice.Services
	|			where Ref = &Ref
	|			and ( IntoFixedAssets
	|				or IntoIntangibleAssets
	|				or IntoItems ) ) as Distribution
	|	on true
	|	//
	|	// Forms
	|	//
	|	left join (
	|		select top 1 true as Exists
	|		from Document.VendorInvoice.Items as Items
	|		where Items.Item.Form
	|		and Items.Ref = &Ref ) as Forms
	|	on true
	|where Documents.Ref = &Ref
	|;
	|// @PurchaseOrderExists
	|select top 1 true as Exist
	|from Document.VendorInvoice.Items as Items
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|and Items.Ref = &Ref
	|union
	|select top 1 true
	|from Document.VendorInvoice.Services as Services
	|where Services.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|and Services.Ref = &Ref
	|union
	|select top 1 true
	|from Document.VendorInvoice as Documents
	|where Documents.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|and Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure setContext ( Env )
	
	Env.Insert ( "PurchaseOrderExists", Env.PurchaseOrderExists <> undefined and Env.PurchaseOrderExists.Exist );
	Env.Insert ( "DistributionRecordsets" );

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

Procedure defineAmount ( Env )
	
	list = new Structure ();
	Env.Insert ( "AmountFields", list );
	fields = Env.Fields;
	foreign = fields.Currency <> fields.LocalCurrency;
	amount = "( Total - VAT )";
	total = "Total";
	if ( foreign ) then
		rate = " * &Rate / &Factor";
		amount = amount + rate;
		total = total + rate;
	endif;
	list.Insert ( "Amount", "cast ( " + amount + " as Number ( 15, 2 ) )" );
	list.Insert ( "Total", "cast ( " + total + " as Number ( 15, 2 ) )" );
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
	
	amount = Env.AmountFields;
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.DiscountRate as DiscountRate, Items.VATCode as VATCode,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse, Items.RowKey as RowKey,
	|	Items.Account as Account, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey, Items.Capacity as Capacity,
	|	Items.Social as Social, Items.Price as Price, Items.ProducerPrice as ProducerPrice, Items.Range as Range, Items.Item.CountPackages as CountPackages,
	|	case when Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef ) then Items.Ref.PurchaseOrder else Items.PurchaseOrder end as PurchaseOrder,
	|	" + amount.Amount + " as Amount, " + amount.ContractAmount + " as ContractAmount, " + amount.Total + " as Total,
	|	" + amount.ContractVAT + " as ContractVAT
	|into Items
	|from Document.VendorInvoice.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series, Items.RowKey, Items.DocumentOrder, Items.DocumentOrderRowKey
	|;
	|select ""Services"" as Table, Services.LineNumber as LineNumber, Services.Item as Item, Services.Feature as Feature,
	|	Services.VATCode as VATCode, Services.RowKey as RowKey, Services.Quantity as Quantity,
	|	Services.DiscountRate as DiscountRate, Services.Description as Description, Services.Account as Account,
	|	Services.Expense as Expense, Services.Department as Department, Services.Product as Product,
	|	Services.ProductFeature as ProductFeature, Services.DocumentOrder as DocumentOrder, Services.DocumentOrderRowKey as DocumentOrderRowKey,
	|	case when Services.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef ) then Services.Ref.PurchaseOrder else Services.PurchaseOrder end as PurchaseOrder,
	|	" + amount.Amount + " as Amount, " + amount.ContractAmount + " as ContractAmount, " + amount.Total + " as Total,
	|	" + amount.ContractVAT + " as ContractVAT";
	if ( Env.Fields.DistributionExists ) then
		s = s + ", Services.IntoFixedAssets as IntoFixedAssets, Services.IntoIntangibleAssets as IntoIntangibleAssets,
		|	Services.IntoItems as IntoItems, Services.Distribution as Distribution, Services.IntoDocument as IntoDocument";
	endif; 
	s = s + "
	|into Services
	|from Document.VendorInvoice.Services as Services
	|where Services.Ref = &Ref
	|index by Services.Item, Services.Feature, Services.RowKey, Services.DocumentOrder, Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlFixedAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|select Items.Acceleration as Acceleration, Items.Charge as Charge,
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.LiquidationValue as LiquidationValue, Items.Method as Method, 
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.Schedule as Schedule, Items.UsefulLife as UsefulLife,
	|	" + amount.Amount + " as Amount, " + amount.ContractAmount + " as ContractAmount,
	|	" + amount.ContractVAT + " as ContractVAT
	|into FixedAssets
	|from Document.VendorInvoice.FixedAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #FixedAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.LiquidationValue as LiquidationValue, Items.Method as Method, 
	|	Items.Item.Account as Account, Items.Starting as Starting, Items.Schedule as Schedule, Items.UsefulLife as UsefulLife,
	|	Items.Amount as Amount, Items.ContractAmount as ContractAmount, Items.ContractVAT as ContractVAT
	|from FixedAssets as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlIntangibleAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.Method as Method, Items.Item.Account as Account, Items.Starting as Starting,
	|	Items.UsefulLife as UsefulLife, " + amount.Amount + " as Amount, " + amount.ContractAmount + " as ContractAmount,
	|	" + amount.ContractVAT + " as ContractVAT
	|into IntangibleAssets
	|from Document.VendorInvoice.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #IntangibleAssets
	|select Items.Acceleration as Acceleration, Items.Charge as Charge, 
	|	Items.Department as Department, Items.Employee as Employee, Items.Expenses as Expenses, Items.Item as Item,
	|	Items.Method as Method, Items.Item.Account as Account, Items.Starting as Starting,
	|	Items.UsefulLife as UsefulLife, Items.Amount as Amount, Items.ContractAmount as ContractAmount,
	|	Items.ContractVAT as ContractVAT
	|from IntangibleAssets as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAccounts ( Env )
	
	amount = Env.AmountFields;
	s = "
	|select Accounts.Account as Account, Accounts.Content as Content, Accounts.Currency as Currency,
	|	Accounts.CurrencyAmount as CurrencyAmount, Accounts.Rate as Rate, Accounts.Factor as Factor,
	|	Accounts.Quantity as Quantity, Accounts.Dim1 as Dim1, Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3,
	|	" + amount.Amount + " as Amount, " + amount.ContractAmount + " as ContractAmount,
	|	" + amount.ContractVAT + " as ContractVAT
	|into Accounts
	|from Document.VendorInvoice.Accounts as Accounts
	|where Accounts.Ref = &Ref
	|;
	|// #Accounts
	|select Accounts.Account as Account, Accounts.Content as Content, Accounts.Currency as Currency,
	|	Accounts.CurrencyAmount as CurrencyAmount, Accounts.Rate as Rate, Accounts.Factor as Factor,
	|	Accounts.Quantity as Quantity, Accounts.Dim1 as Dim1, Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3,
	|	Accounts.Amount as Amount, Accounts.ContractAmount as ContractAmount, Accounts.ContractVAT as ContractVAT
	|from Accounts as Accounts
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDiscounts ( Env )
	
	vat = "VAT";
	amount = "( Amount - VAT )";
	fields = Env.Fields;
	if ( fields.ContractCurrency <> fields.LocalCurrency ) then
		vat = vat + " * &Rate / &Factor";
		amount = amount + " * &Rate / &Factor";
	endif; 
	s = "
	|select Discounts.PurchaseOrder as PurchaseOrder, Discounts.Item as Item, Discounts.VATCode as VATCode,
	|	Discounts.VATAccount as VATAccount, Discounts.Income as Income, Details.ItemKey as ItemKey,
	|	Discounts.VAT as ContractVAT, Discounts.Amount - Discounts.VAT as ContractAmount, Discounts.Amount as Total, "
	+ amount + " as Amount,"
	+ vat + " as VAT"
	+ "
	|into Discounts
	|from Document.VendorInvoice.Discounts as Discounts
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
	|		select FixedAssets.Amount, FixedAssets.ContractAmount, 0
	|		from FixedAssets as FixedAssets
	|		union all
	|		select IntangibleAssets.Amount, IntangibleAssets.ContractAmount, 0
	|		from IntangibleAssets as IntangibleAssets
	|		union all
	|		select Accounts.Amount, Accounts.ContractAmount, 0
	|		from Accounts as Accounts
	|		union all
	|		select " + fields.VAT + ", " + fields.ContractVAT + ", " + fields.ContractVAT + "
	|		from Document.VendorInvoice as Document
	|		where Document.Ref = &Ref ) as Items
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
	if ( Env.PurchaseOrderExists ) then
		s = s + "
		|union all
		|select Items.LineNumber, Items.Table, Items.PurchaseOrder
		|from Items as Items
		|	//
		|	// PurchaseOrders
		|	//
		|	left join Document.PurchaseOrder.Items as PurchaseOrders
		|	on PurchaseOrders.Ref = Items.PurchaseOrder
		|	and PurchaseOrders.RowKey = Items.RowKey
		|	and PurchaseOrders.Item = Items.Item
		|	and PurchaseOrders.Feature = Items.Feature
		|	and PurchaseOrders.DiscountRate = Items.DiscountRate
		|where PurchaseOrders.RowKey is null
		|union
		|select Services.LineNumber, Services.Table, Services.PurchaseOrder
		|from Services as Services
		|	//
		|	// PurchaseOrders
		|	//
		|	left join Document.PurchaseOrder.Services as PurchaseOrders
		|	on PurchaseOrders.Ref = Services.PurchaseOrder
		|	and PurchaseOrders.RowKey = Services.RowKey
		|	and PurchaseOrders.Item = Services.Item
		|	and PurchaseOrders.Feature = Services.Feature
		|	and ( PurchaseOrders.DiscountRate = Services.DiscountRate
		|		or ( PurchaseOrders.Quantity = 0 and Services.Quantity = 0 ) )
		|where PurchaseOrders.RowKey is null
		|";
	endif; 
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlCost ( Env )
	
	s = "
	|// #Cost
	|select Items.Item as Item, Items.Item.CostMethod as CostMethod, Items.Package as Package, Items.Feature as Feature,
	|	Items.Series as Series, Items.Warehouse as Warehouse, Items.Account as Account, Details.ItemKey as Itemkey,
	|	Items.QuantityPkg as Quantity, Items.Quantity as Units, Items.Amount as Amount,
	|	Items.ContractAmount as ContractAmount, Items.VATCode as VATCode
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

Procedure sqlReserves ( Env )
	
	s = "
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as RowKey, 
	|	Items.Warehouse as Warehouse, Items.Quantity as Quantity
	|into Reserves
	|from Items as Items
	|where Items.DocumentOrder refs Document.SalesOrder
	|union all
	|select Items.LineNumber, SalesOrders.Ref, SalesOrders.RowKey, Items.Warehouse, Items.Quantity
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.DocumentOrder = Items.PurchaseOrder
	|	and SalesOrders.DocumentOrderRowKey = Items.RowKey
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|union all
	|select Items.LineNumber, Items.DocumentOrder, Items.DocumentOrderRowKey, Items.Warehouse, Items.Quantity as Quantity
	|from Items as Items
	|where Items.DocumentOrder refs Document.InternalOrder
	|and cast ( Items.DocumentOrder as Document.InternalOrder ).Warehouse <> Items.Warehouse
	|union all
	|select Items.LineNumber, InternalOrders.Ref, InternalOrders.RowKey, Items.Warehouse, Items.Quantity
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.DocumentOrder = Items.PurchaseOrder
	|	and InternalOrders.DocumentOrderRowKey = Items.RowKey
	|	and InternalOrders.Ref.Warehouse <> Items.Warehouse
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|;
	|// ^Reserves
	|select Reserves.DocumentOrder as DocumentOrder, Reserves.RowKey as RowKey, Reserves.Warehouse as Warehouse, Reserves.Quantity as Quantity
	|from Reserves as Reserves
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlWarehouse ( Env )
	
	s = "
	|// ^Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Warehouse as Warehouse, Items.Package as Package,
	|	sum ( Items.QuantityPkg - case when Items.CountPackages then isnull ( Reserves.Quantity, 0 ) / Items.Capacity else isnull ( Reserves.Quantity, 0 ) end ) as Quantity
	|from Items as Items
	|	//
	|	// Reserves
	|	//
	|	left join Reserves as Reserves
	|	on Reserves.LineNumber = Items.LineNumber
	|group by Items.Item, Items.Feature, Items.Warehouse, Items.Package
	|having sum ( Items.QuantityPkg - case when Items.CountPackages then isnull ( Reserves.Quantity, 0 ) / Items.Capacity else isnull ( Reserves.Quantity, 0 ) end ) > 0
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
	|union all
	|select InternalOrders.Ref as InternalOrder, InternalOrders.RowKey as RowKey,
	|	Items.Quantity
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.DocumentOrder = Items.PurchaseOrder
	|	and InternalOrders.DocumentOrderRowKey = Items.RowKey
	|	and InternalOrders.Ref.Warehouse = Items.Warehouse
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
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
	
	if ( Env.Fields.DistributionExists ) then
		flag = "case when Services.IntoIntangibleAssets or Services.IntoFixedAssets or Services.IntoItems then true else false end";
	else
		flag = "false";
	endif; 
	s = "
	|// #Expenses
	|select Services.Item as Item, Services.Feature as Feature, Services.Account as Account, Services.Expense as Expense,
	|	Services.Department as Department, Services.Product as Product, Services.ProductFeature as ProductFeature,
	|	Services.Description as Description, Services.VATCode as VATCode,
	|	sum ( Services.Quantity ) as Quantity, sum ( Services.Amount ) as Amount,
	|	sum ( Services.ContractAmount ) as ContractAmount, Details.ItemKey as Itemkey,
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
	|	Services.VATCode, Services.Product, Services.ProductFeature, Services.Description, Details.ItemKey, " + flag + "
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlDistributingExpenses ( Env )
	
	s = "
	|// ^DistributingExpenses
	|select Services.LineNumber as ServicesLineNumber, Services.Amount as Amount, Services.ContractAmount as ContractAmount,
	|	Services.Item as ServicesItem, Services.Item.Description as ServicesItemDescription,
	|	case when Services.IntoDocument = value ( Document.VendorInvoice.EmptyRef ) then &Ref else Services.IntoDocument end as Document,
	|	Services.IntoFixedAssets as IntoFixedAssets, Services.IntoIntangibleAssets as IntoIntangibleAssets,	Services.IntoItems as IntoItems, 
	|	case when Services.Distribution = value ( Enum.Distribution.Quantity ) then ""Quantity""
	|		when Services.Distribution = value ( Enum.Distribution.Amount ) then ""Amount""
	|		when Services.Distribution = value ( Enum.Distribution.Weight ) then ""Weight""
	|	end as DistributeColumn
	|from Services as Services
	|where Services.IntoFixedAssets
	|or Services.IntoIntangibleAssets
	|or Services.IntoItems
	|;
	|select distinct
	|	case when Services.IntoDocument = value ( Document.VendorInvoice.EmptyRef ) then &Ref else Services.IntoDocument end as Document,
	|	isnull ( ExchangeRates.Rate, 1 ) as Rate, isnull ( ExchangeRates.Factor, 1 ) as Factor
	|into Accepters
	|from Services as Services
	|	//
	|	// ExchangeRates
	|	//
	|	left join InformationRegister.ExchangeRates.SliceLast ( &Timestamp ) as ExchangeRates
	|	on ExchangeRates.Currency = case when Services.IntoDocument = value ( Document.VendorInvoice.EmptyRef ) then &Currency else Services.IntoDocument.Currency end
	|where Services.IntoFixedAssets
	|or Services.IntoIntangibleAssets
	|or Services.IntoItems
	|index by Document
	|;
	|// ^DistributionBase
	|select value ( Enum.Tables.Items ) as Table, Goods.LineNumber as LineNumber, Goods.Ref as Document, Goods.Ref.Date as Date,
	|	Goods.Quantity as Quantity, Goods.Quantity * Goods.Item.Weight as Weight, Goods.Amount * Accepters.Rate / Accepters.Factor as Amount,
	|	Goods.Item as Item, Goods.Account as Account,
	|	Goods.Package as Package, Goods.Feature as Feature, Goods.Series as Series,
	|	case when Goods.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Goods.Ref.Warehouse else Goods.Warehouse end as Warehouse,
	|	case when Goods.Item.CostMethod = value ( Enum.Cost.Avg ) then value ( Catalog.Lots.EmptyRef ) else Lots.Ref end as Lot,
	|	Details.ItemKey as ItemKey
	|from Document.VendorInvoice.Items as Goods
	|	//
	|	// Details
	|	//
	|	left join InformationRegister.ItemDetails as Details
	|	on Details.Item = Goods.Item
	|	and Details.Package = case when Goods.Item.CountPackages then Goods.Package else null end
	|	and Details.Feature = Goods.Feature
	|	and Details.Warehouse = ( case when Goods.Warehouse = value ( Catalog.Warehouses.EmptyRef ) then Goods.Ref.Warehouse else Goods.Warehouse end )
	|	and Details.Series = Goods.Series
	|	and Details.Account = Goods.Account
	|	//
	|	// Accepters
	|	//
	|	join Accepters as Accepters
	|	on Accepters.Document = Goods.Ref
	|	//
	|	// Lots
	|	//
	|	left join Catalog.Lots as Lots
	|	on Lots.Document = Goods.Ref
	|where Goods.Ref.Posted
	|union all
	|select value ( Enum.Tables.FixedAssets ), FixedAssets.LineNumber, FixedAssets.Ref, FixedAssets.Ref.Date, 1, FixedAssets.Item.Weight, FixedAssets.Amount,
	|	FixedAssets.Item, FixedAssets.Item.Account, null, null, null, null, null, null
	|from Document.VendorInvoice.FixedAssets as FixedAssets
	|	//
	|	// Accepters
	|	//
	|	join Accepters as Accepters
	|	on Accepters.Document = FixedAssets.Ref
	|where FixedAssets.Ref.Posted
	|union all
	|select value ( Enum.Tables.IntangibleAssets ), IntangibleAssets.LineNumber, IntangibleAssets.Ref, IntangibleAssets.Ref.Date, 1, 0, IntangibleAssets.Amount,
	|	IntangibleAssets.Item, IntangibleAssets.Item.Account,
	|	null, null, null, null, null, null
	|from Document.VendorInvoice.IntangibleAssets as IntangibleAssets
	|	//
	|	// Accepters
	|	//
	|	join Accepters as Accepters
	|	on Accepters.Document = IntangibleAssets.Ref
	|where IntangibleAssets.Ref.Posted
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure sqlPurchaseOrders ( Env )
	
	s = "
	|// ^PurchaseOrders
	|select Items.PurchaseOrder as PurchaseOrder, Items.RowKey as RowKey, Items.Quantity as Quantity, Items.Total as Amount
	|from Items as Items
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|union all
	|select Services.PurchaseOrder, Services.RowKey, Services.Quantity, Services.Total
	|from Services as Services
	|where Services.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProvision ( Env )
	
	s = "
	|// ^Provision
	|select Items.PurchaseOrder as DocumentOrder, Items.RowKey as RowKey, sum ( Items.Quantity ) as Quantity
	|from Items as Items
	|	//
	|	// PurchaseOrders
	|	//
	|	join Document.PurchaseOrder.Items as PurchaseOrders
	|	on PurchaseOrders.Ref = Items.PurchaseOrder
	|	and PurchaseOrders.RowKey = Items.RowKey
	|	and PurchaseOrders.Provision = value ( Enum.Provision.Free )
	|group by Items.PurchaseOrder, Items.RowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlAllocation ( Env )
	
	s = "
	|// ^Allocation
	|select Items.Table as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature,
	|	Items.Quantity as Quantity, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey
	|from Items as Items
	|	//
	|	// Release allocations for IO
	|	//
	|	join Document.InternalOrder.Items as IOItems
	|	on IOItems.Ref = Items.DocumentOrder
	|	and IOItems.RowKey = Items.DocumentOrderRowKey
	|	and IOItems.Reservation = value ( Enum.Reservation.Invoice )
	|union all
	|select Items.Table, Items.LineNumber, Items.Item, Items.Feature, Items.Quantity, Items.DocumentOrder, Items.DocumentOrderRowKey
	|from Items as Items
	|	//
	|	// Release allocations for SO
	|	//
	|	join Document.SalesOrder.Items as SOItems
	|	on SOItems.Ref = Items.DocumentOrder
	|	and SOItems.RowKey = Items.DocumentOrderRowKey
	|	and SOItems.Reservation = value ( Enum.Reservation.Invoice )
	|union all
	|select Services.Table, Services.LineNumber, Services.Item, Services.Feature, Services.Quantity, Services.DocumentOrder, Services.DocumentOrderRowKey
	|from Services as Services
	|	//
	|	// Release allocations for IO
	|	//
	|	join Document.InternalOrder.Services as IOServices
	|	on IOServices.Ref = Services.DocumentOrder
	|	and IOServices.RowKey = Services.DocumentOrderRowKey
	|	and IOServices.Performer = value ( Enum.Performers.Vendor )
	|union all
	|select Services.Table, Services.LineNumber, Services.Item, Services.Feature, Services.Quantity, Services.DocumentOrder, Services.DocumentOrderRowKey
	|from Services as Services
	|	//
	|	// Release allocations for SO
	|	//
	|	join Document.SalesOrder.Services as SOServices
	|	on SOServices.Ref = Services.DocumentOrder
	|	and SOServices.RowKey = Services.DocumentOrderRowKey
	|	and SOServices.Performer = value ( Enum.Performers.Vendor )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	fields = Env.Fields;
	Env.Q.SetParameter ( "Warehouse", fields.Warehouse );
	Env.Q.SetParameter ( "Timestamp", fields.Timestamp );
	Env.Q.SetParameter ( "Rate", fields.Rate );
	Env.Q.SetParameter ( "Factor", fields.Factor );
	if ( fields.DistributionExists ) then
		Env.Q.SetParameter ( "Currency", fields.Currency );
	endif; 
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure 

Function invalidRows ( Env )
	
	table = SQL.Fetch ( Env, "$InvalidRows" );
	for each row in table do
		Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( row.Table, row.LineNumber, "Item" ), Env.Ref );
	enddo; 
	return table.Count () > 0;
	
EndFunction

Function applyDiscount ( Env )
	
	discounts = prepareDiscounts ( Env );
	decreaseCost ( Env, discounts );
	if ( discounts.Count () > 0 ) then
		ref = Env.Ref;
		for each row in discounts do
			Output.CannotApplyDiscount ( new Structure ( "Discount", Conversion.NumberToMoney ( row.Amount ) ),
				"Discounts", ref );
		enddo;
		return false;
	endif;
	return true;
	
EndFunction

Function prepareDiscounts ( Env )
	
	discounts = Env.Discounts.Copy ();
	amountType = Metadata.AccountingRegisters.General.Resources.Amount.Type;
	CollectionsSrv.Adjust ( discounts, "Amount", amountType );
	CollectionsSrv.Adjust ( discounts, "ContractAmount", amountType );
	return discounts;
	
EndFunction

Procedure decreaseCost ( Env, Discounts )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "VATCode" );
	p.Insert ( "DistribColumnsTable1", "Amount, ContractAmount" );
	p.Insert ( "KeyColumn", "Amount" );
	cost = Env.Cost;
	table = CollectionsSrv.Combine ( Discounts, cost, p );
	for each discount in table do
		row = cost.Add ();
		FillPropertyValues ( row, discount );
		row.Quantity = 0;
		row.Units = 0;
		row.Amount = - row.Amount;
		row.ContractAmount = - row.ContractAmount;
	enddo;
	if ( discounts.Count () = 0 ) then
		return;
	endif;
	expenses = Env.Expenses;
	table = CollectionsSrv.Combine ( Discounts, expenses, p );
	for each discount in table do
		row = expenses.Add ();
		FillPropertyValues ( row, discount );
		row.Quantity = 0;
		row.Amount = - row.Amount;
		row.ContractAmount = - row.ContractAmount;
	enddo;
	
EndProcedure

Procedure makeValues ( Env )

	ItemDetails.Init ( Env );
	makeCost ( Env );
	makeExpenses ( Env );
	commitExpenses ( Env );
	ItemDetails.Save ( Env );
	
EndProcedure

Procedure makeCost ( Env )
	
	p = GeneralRecords.GetParams ();
	recordset = Env.Registers.Cost;
	fields = Env.Fields;
	lot = fields.Lot;
	date = fields.Date;
	for each row in Env.Cost do
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
	Params.AccountCr = fields.VendorAccount;
	Params.Operation = Enums.Operations.ItemsReceipt;
	Params.Amount = row.Amount;
	Params.QuantityDr = row.Units;
	Params.DimDr1 = row.Item;
	Params.DimDr2 = row.Warehouse;
	Params.DimCr1 = fields.Vendor;
	Params.DimCr2 = fields.Contract;
	Params.CurrencyCr = fields.ContractCurrency;
	Params.CurrencyAmountCr = row.ContractAmount;
	Params.Recordset = Env.Registers.General;
	GeneralRecords.Add ( Params );

EndProcedure

Procedure makeExpenses ( Env )

	fields = Env.Fields;
	date = fields.Date;
	recordset = Env.Registers.Expenses;
	for each row in Env.Expenses do
		movement = recordset.Add ();
		movement.Period = date;
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, , row.Feature );
		endif; 
		movement.Document = Env.Ref;
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

Procedure commitExpenses ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.ExpenseReceipt;
	p.Recordset = Env.Registers.General;
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	for each row in Env.Expenses do
		if ( row.Distribute ) then
			continue;
		endif; 
		p.AccountDr = row.Account;
		p.AccountCr = vendorAccount;
		p.Amount = row.Amount;
		p.QuantityDr = row.Quantity;
		p.DimDr1 = row.Expense;
		p.DimDr2 = row.Department;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.ContractAmount;
		p.Content = row.Description;
		GeneralRecords.Add ( p );
	enddo; 

EndProcedure

Function distributeExpenses ( Env )
	
	if ( not Env.Fields.DistributionExists ) then
		return true;
	endif;
	table = getDistribution ( Env );
	if ( table = undefined ) then
		return false;
	endif; 
	saveDistribution ( Env, table );
	return true;

EndFunction

Function getDistribution ( Env )
	
	result = new ValueTable ();
	tables = getDistributingTables ( Env );
	if ( tables.Base.Count () = 0 ) then
		Output.BaseNotFound ( , , Env.Ref );
		return undefined;
	endif; 
	p = getDistributingParams ( Env );
	for each expensesRow in tables.Expenses do
		tables.ExpensesByRow.Clear ();
		row = tables.ExpensesByRow.Add ();
		FillPropertyValues ( row, expensesRow );
		tables.BaseByRow.Clear ();
		for each baseRow in tables.Base do
			if ( expensesRow.IntoFixedAssets and baseRow.Table = Enums.Tables.FixedAssets )
				or ( expensesRow.IntoIntangibleAssets and baseRow.Table = Enums.Tables.IntangibleAssets )
				or ( expensesRow.IntoItems and baseRow.Table = Enums.Tables.Items ) then
				row = tables.BaseByRow.Add ();
				FillPropertyValues ( row, baseRow );
			endif; 
		enddo; 
		p.Insert ( "KeyColumn", expensesRow.DistributeColumn );
		CollectionsSrv.Join ( result, CollectionsSrv.Combine ( tables.ExpensesByRow, tables.BaseByRow, p ) );
		if ( tables.ExpensesByRow.Count () > 0 ) then
			// Error....
			return undefined;
		endif; 
	enddo; 
	return result;
	
EndFunction 

Function getDistributingTables ( Env )
	
	tables = new Structure ();
	tables.Insert ( "Expenses", SQL.Fetch ( Env, "$DistributingExpenses" ) );
	tables.Insert ( "ExpensesByRow", tables.Expenses.CopyColumns () );
	amountType = Metadata.AccountingRegisters.General.Resources.Amount.Type;
	CollectionsSrv.Adjust ( tables.ExpensesByRow, "Amount", amountType );
	CollectionsSrv.Adjust ( tables.ExpensesByRow, "ContractAmount", amountType );
	tables.Insert ( "Base", getBase ( Env ) );
	tables.Insert ( "BaseByRow", tables.Base.CopyColumns () );
	return tables;
	
EndFunction 

Function getBase ( Env )
	
	table = SQL.Fetch ( Env, "$DistributionBase" );
	for each row in table do
		if ( row.Table = Enums.Tables.Items
			and row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item, row.Package, row.Feature, row.Series, row.Warehouse, row.Account );
		endif; 
	enddo;
	return table;

EndFunction 

Function getDistributingParams ( Env )
	
	p = new Structure ();
	p.Insert ( "FilterColumns", "Document" );
	p.Insert ( "DistribColumnsTable1", "Amount, ContractAmount" );
	p.Insert ( "DistributeTables" );
	p.Insert ( "AssignСоlumnsTаble1", "ServicesItem, ServicesItemDescription, ServicesLineNumber" );
	p.Insert ( "AssignColumnsTable2", "Table, Document, Item, Warehouse, Account, ItemKey, Lot, Date, LineNumber" );
	return p;
	
EndFunction 

Procedure saveDistribution ( Env, DistributedExpenses )
	
	fields = Env.Fields;
	Env.DistributionRecordsets = new Map ();
	entry = GeneralRecords.GetParams ();
	entry.Date = fields.Date;
	entry.Company = fields.Company;
	entry.Operation = Enums.Operations.AdditionalExpenses;
	for each row in DistributedExpenses do
		if ( row.Table = Enums.Tables.Items ) then
			makeAdditionalCost ( Env, row, entry );
		endif; 
		commitAdditionalCost ( Env, row, entry );
		makeItemExpenses ( Env, row );
	enddo; 

EndProcedure 

Procedure makeAdditionalCost ( Env, Row, Entry )
	
	recordset = distributionRecordset ( Env, row.Document, "Cost" );
	movement = recordset.Add ();
	movement.Period = Row.Date;
	movement.ItemKey = Row.ItemKey;
	movement.Lot = Row.Lot;
	movement.Amount = Row.Amount;
	if ( Env.Ref <> Row.Document ) then
		ref = Env.Ref;
		Entry.Dependency = ref;
		movement.Dependency = ref;
	endif; 
	
EndProcedure 

Function distributionRecordset ( Env, Document, Name )
	
	if ( Env.DistributionRecordsets [ Name ] = undefined ) then
		Env.DistributionRecordsets [ Name ] = new Map ();
	endif; 
	recordsets = Env.DistributionRecordsets [ Name ];
	recordset = recordsets [ Document ];
	if ( recordset = undefined ) then
		if ( Name = "General" ) then
			if ( Document = Env.Ref ) then
				return Env.Registers.General;
			else
				recordset = AccountingRegisters.General.CreateRecordSet ();
				recordset.Filter.Recorder.Set ( Document );
				recordsets [ Document ] = recordset;
				return recordset;
			endif; 
		elsif ( Name = "Cost" ) then
			if ( Document = Env.Ref ) then
				return Env.Registers.Cost;
			else
				recordset = AccumulationRegisters.Cost.CreateRecordSet ();
				recordset.Filter.Recorder.Set ( Document );
				recordsets [ Document ] = recordset;
				return recordset;
			endif; 
		endif; 
	else
		return recordset;
	endif; 
	
EndFunction 

Procedure commitAdditionalCost ( Env, Row, Entry )
	
	fields = Env.Fields;
	if ( Row.Table = Enums.Tables.Items ) then
		Entry.DimDr1 = Row.Item;
		Entry.DimDr2 = Row.Warehouse;
	elsif ( Row.Table = Enums.Tables.FixedAssets ) then
		Entry.DimDr1 = Row.Item;
		Entry.DimDr2 = undefined;
		Entry.DimDr2Type = undefined;
	elsif ( Row.Table = Enums.Tables.IntangibleAssets ) then
		Entry.DimDr1 = Row.Item;
		Entry.DimDr2 = undefined;
		Entry.DimDr2Type = undefined;
	endif; 
	if ( Env.Ref <> Row.Document ) then
		Entry.Dependency = Env.Ref;
	endif; 
	Entry.AccountDr = row.Account;
	Entry.AccountCr = fields.VendorAccount;
	Entry.DimCr1 = fields.Vendor;
	Entry.DimCr2 = fields.Contract;
	Entry.CurrencyCr = fields.Currency;
	Entry.CurrencyAmountCr = row.ContractAmount;
	Entry.Amount = row.Amount;
	Entry.Recordset = distributionRecordset ( Env, row.Document, "General" );
	Entry.Content = getContent ( Entry, row );
	GeneralRecords.Add ( Entry );
	
EndProcedure 

Function getContent ( Entry, Row )
	
	return "" + Entry.Operation + ": " + row.ServicesItemDescription;
	
EndFunction 

Procedure makeItemExpenses ( Env, Row )
	
	movement = Env.Registers.ItemExpenses.Add ();
	movement.Date = Row.Date;
	movement.Document = Row.Document;
	movement.DocumentTable = Row.Table;
	movement.DocumentRow = Row.LineNumber;
	movement.Source = Env.Ref;
	movement.Table = Enums.Tables.Services;
	movement.TableRow = Row.ServicesLineNumber;
	movement.Amount = row.Amount;
	
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
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		item = row.Item;
		movement = depreciation.Add ();
		movement.Period = startDepreciation;
		movement.Asset = item;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.LiquidationValue = row.LiquidationValue;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.Schedule = row.Schedule;
		movement.UsefulLife = row.UsefulLife;
		movement = location.Add ();
		movement.Period = date;
		movement.Asset = item;
		movement.Employee = row.Employee;
		movement.Department = row.Department;
		p.AccountDr = row.Account;
		p.QuantityDr = 1;
		p.Amount = row.Amount;
		p.DimDr1 = item;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.ContractAmount;
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
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	p = GeneralRecords.GetParams ();
	p.Date = date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		item = row.Item;
		movement = amortization.Add ();
		movement.Period = date;
		movement.Asset = item;
		movement.Acceleration = row.Acceleration;
		movement.Charge = row.Charge;
		movement.Expenses = row.Expenses;
		movement.Method = row.Method;
		movement.Starting = row.Starting;
		movement.UsefulLife = row.UsefulLife;
		movement = location.Add ();
		movement.Period = date;
		movement.Asset = item;
		movement.Employee = row.Employee;
		movement.Department = row.Department;
		p.AccountDr = row.Account;
		p.QuantityDr = 1;
		p.Amount = row.Amount;
		p.DimDr1 = item;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.ContractAmount;
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
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	for each row in table do
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		p.QuantityDr = row.Quantity;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
		p.CurrencyDr = row.Currency;
		p.CurrencyAmountDr = row.CurrencyAmount;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = row.ContractAmount;
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
	table = SQL.Fetch ( Env, "$Reserves" );
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

Procedure makePurchaseOrders ( Env )

	if ( not Env.PurchaseOrderExists ) then
		return;
	endif;
	table = SQL.Fetch ( Env, "$PurchaseOrders" );
	Env.Insert ( "AllocationExists", false );
	recordset = Env.Registers.PurchaseOrders;
	date = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.PurchaseOrder = row.PurchaseOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	
EndProcedure
 
Procedure makeAllocations ( Env )
	
	if ( Env.PurchaseOrderExists ) then
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

Procedure makeProvision ( Env )
	
	if ( not Env.PurchaseOrderExists ) then
		return;
	endif;
	table = SQL.Fetch ( Env, "$Provision" );
	recordset = Env.Registers.Provision;
	date = Env.Fields.Date;
	for each row in Table do
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.RowKey;
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
	purchaseOrders = registers.PurchaseOrders;
	if ( Env.PurchaseOrderExists ) then
		purchaseOrders.LockForUpdate = true;
		purchaseOrders.Write ();
		Shortage.SqlPurchaseOrders ( Env );
	else
		purchaseOrders.Write = true;
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
	if ( Env.PurchaseOrderExists ) then
		table = SQL.Fetch ( Env, "$ShortagePurchaseOrders" );
		if ( table.Count () > 0 ) then
			Shortage.PurchaseOrders ( Env, table );
			return false;
		endif; 
	endif; 
	return true;
		
EndFunction

Procedure writeDistribution ( Env )
	
	if ( Env.Fields.DistributionExists ) then
		for each recordsetType in Env.DistributionRecordsets do
			for each recordset in recordsetType.Value do
				recordset.Value.Write ( false );
			enddo; 
		enddo; 
	endif; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Expenses.Write = true;
	registers.Items.Write = true;
	registers.Cost.Write = true;
	registers.Reserves.Write = true;
	registers.VendorDebts.Write = true;
	registers.Provision.Write = true;
	registers.VendorServices.Write = true;
	registers.ItemExpenses.Write = true;
	registers.Amortization.Write = true;
	registers.Depreciation.Write = true;
	registers.FixedAssetsLocation.Write = true;
	registers.IntangibleAssetsLocation.Write = true;
	registers.ProducerPrices.Write = true;
	registers.RangeLocations.Write = true;
	registers.RangeStatuses.Write = true;
	registers.VendorDiscounts.Write = true;
	
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

Procedure sqlVAT ( Env )
	
	amount = Env.AmountFields;
	fields = "VATAccount as Account, " + amount.VAT + " as Amount, " + amount.ContractVAT + " as ContractAmount";
	s = "
	|// #VAT
	|select Taxes.Account as Account, sum ( Taxes.Amount ) as Amount, sum ( ContractAmount ) as ContractAmount
	|from (
	|	select " + fields + "
	|	from Document.VendorInvoice.Items as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorInvoice.Services as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorInvoice.FixedAssets as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorInvoice.IntangibleAssets as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorInvoice.Accounts as Records
	|	where Records.Ref = &Ref
	|	union all
	|	select Discounts.VATAccount, sum ( - Discounts.VAT ), sum ( - Discounts.Amount )
	|	from Discounts as Discounts
	|	group by Discounts.VATAccount
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

Procedure makeDiscounts ( Env )

	fields = Env.Fields;
	amount = fields.PaymentDiscount;
	if ( amount = 0 ) then
		return;
	endif;
	date = fields.Date;
	ref = Env.Ref;
	discounts = Env.Registers.VendorDiscounts;
	sales = Env.Registers.Sales;
	for each row in Env.Discounts do
		if ( row.ItemKey = null ) then
			row.ItemKey = ItemDetails.GetKey ( Env, row.Item );
		endif; 
		movement = discounts.Add ();
		movement.Period = date;
		movement.Document = ref;
		movement.Detail = row.PurchaseOrder;
		movement.Amount = row.Total;
//		movement = sales.Add ();
//		movement.Period = date;
//		movement.ItemKey = row.ItemKey;
//		movement.Department = department;
//		movement.Account = row.Income;
//		movement.Amount = - row.Amount;
//		movement.SalesOrder = row.SalesOrder;
//		rowSales = salesTable.Add ();
//		rowSales.Operation = Enums.Operations.SalesDiscount;
//		rowSales.Income = row.Income;
//		rowSales.Amount = - ( row.Amount - row.VAT );
//		rowSales.ContractAmount = - row.ContractAmount;
	enddo;

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
	p.AccountCr = fields.VendorAccount;
	p.DimCr1 = fields.Vendor;
	p.DimCr2 = fields.Contract;
	p.CurrencyCr = fields.ContractCurrency;
	p.Operation = Enums.Operations.VATReceivable;
	p.Recordset = Env.Registers.General;
	contractVAT = 0;
	for each row in table do
		vat = row.ContractAmount;
		p.CurrencyAmountCr = vat;
		p.AccountDr = row.Account;
		p.Amount = row.Amount;
		record = GeneralRecords.Add ( p );
		contractVAT = contractVAT + vat;
	enddo; 
	amount = Env.ContractAmount;
	if ( contractVAT <> amount.ContractVAT
		and p.DataCr.Fields.Currency ) then
		record.CurrencyAmountCr = record.CurrencyAmountCr + ( amount.ContractVAT - contractVAT );
	endif; 
	
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

#endif