#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.VendorReturn.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	restoreCost = Env.RestoreCost;
	costOnline = Env.CostOnline;
	realTime = Env.Realtime;
	if ( invalidRows ( Env ) ) then
		return false;		
	endif; 
	if ( not restoreCost ) then
		if ( not makeFixedAssets ( Env ) )
			or ( not makeIntangibleAssets ( Env ) ) then
			return false;			
		endif;
		makeItems ( Env );
		makeAccounts ( Env );
		if ( not RunDebts.FromInvoice ( Env ) ) then
			return false;
		endif;
		makeInternalOrders ( Env );	
		makeAllocation ( Env );
		makeReserves ( Env );
		makePurchaseOrders ( Env );
		makeProvision ( Env );
	endif;
	if ( restoreCost
		or costOnline ) then
		if ( not makeValues ( Env ) ) then
			return false;	
		endif;
	endif;
	if ( not restoreCost ) then
		makeVAT ( Env );		
		attachSequence ( Env );
		if ( not realTime ) then
			SequenceCost.Rollback ( Env.Ref, Env.Fields.Company, Env.Fields.Timestamp );
		endif;
		if ( not checkBalances ( Env ) ) then
			return false;				
		endif;
	endif; 
	flagRegisters ( Env );
	return true;
	
EndFunction
 
Function getData ( Env )
	
	sqlFields ( Env );
	getFields ( Env );
	setContext ( Env );
	defineAmount ( Env );
	sqlItems ( Env );
	restoreCost = Env.RestoreCost;
	costOnline = Env.CostOnline;
	sqlInvalidRows ( Env );
	if ( not restoreCost ) then
		sqlFixedAssets ( Env );
		sqlIntangibleAssets ( Env );
		sqlAccounts ( Env );
		sqlReserves ( Env );
		sqlWarehouse ( Env );
		sqlInternalOrders ( Env );	
		sqlAllocation ( Env );
		sqlPurchaseOrders ( Env );
		sqlProvision ( Env );
		sqlContractAmount ( Env );
		sqlVAT ( Env );
		sqlSequence ( Env );		
	endif;
	if ( restoreCost
		or costOnline ) then
		sqlItemKeys ( Env );
		sqlItemsAndKeys ( Env );
		sqlCost ( Env );
	endif;
	getTables ( Env );
	if ( not restoreCost ) then
		amount = Env.ContractAmount;
		fields = Env.Fields;
		fields.Insert ( "Amount", amount.Amount );
		fields.Insert ( "ContractAmount", amount.ContractAmount );
	endif; 
	return true;
	
EndFunction

Procedure sqlFields ( Env )
	
	paymentDate = "case when Documents.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Documents.PaymentDate end";
	s = "
	|// @Fields
	|select top 1 Documents.Warehouse as Warehouse, Documents.Vendor as Vendor, Documents.Currency as Currency,
	|	Documents.Company as Company, Documents.Contract as Contract, Documents.PointInTime as Timestamp,
	|	Documents.Rate as Rate, Documents.Factor as Factor, Constants.Currency as LocalCurrency,
	|	Documents.VendorAccount as VendorAccount, Documents.Date as Date, " + paymentDate + " as PaymentDate, 
	|	Documents.PaymentOption as PaymentOption, PaymentDetails.PaymentKey as PaymentKey, 
	|	Documents.Contract.Currency as ContractCurrency, Documents.Contract.VendorAdvancesMonthly as AdvancesMonthly,
	|	Documents.CloseAdvances as CloseAdvances
	|from Document.VendorReturn as Documents
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Documents.PaymentOption
	|	and PaymentDetails.Date = " + paymentDate + "
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|;
	|// @PurchaseOrderExists
	|select top 1 true as Exist
	|from Document.VendorReturn.Items as Items
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|and Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure setContext ( Env )
	
	fields = Env.Fields;
	Env.Insert ( "PurchaseOrderExists", Env.PurchaseOrderExists <> undefined and Env.PurchaseOrderExists.Exist );
	Env.Insert ( "CheckBalances", Shortage.Check ( fields.Company, Env.Realtime, Env.RestoreCost ) );
	Env.Insert ( "CostOnline", Options.CostOnline ( fields.Company ) );

EndProcedure

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
	contractTotal = "Total";
	if ( fields.ContractCurrency <> fields.Currency ) then
		if ( fields.Currency = fields.LocalCurrency ) then
			rate = " / &Rate * &Factor";
		else
			rate = " * &Rate / &Factor";
		endif;
		contractAmount = contractAmount + rate;
		contractVAT = contractVAT + rate;
		contractTotal = contractTotal + rate;
	endif; 
	if ( foreign ) then
		rate = " * &Rate / &Factor";
		vat = vat + rate;
	endif;
	list.Insert ( "ContractVAT", "cast ( " + contractVAT + " as Number ( 15, 2 ) )" );
	list.Insert ( "ContractAmount", "cast ( " + contractAmount + " as Number ( 15, 2 ) )" );
	list.Insert ( "ContractTotal", "cast ( " + contractTotal + " as Number ( 15, 2 ) )" );
	list.Insert ( "VAT", "cast ( " + vat + " as Number ( 15, 2 ) )" );

EndProcedure 

Procedure sqlItems ( Env )
	
	amount = Env.AmountFields;
	s = "
	|// Items
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Quantity as Quantity, Items.DiscountRate as DiscountRate, Items.RowKey as RowKey, Items.Item.CountPackages as CountPackages,
	|	case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end as QuantityPkg,
	|	case when Items.Item.CountPackages then Items.Package else value ( Catalog.Packages.EmptyRef ) end as Package,
	|	case when ( Items.Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) then &Warehouse else Items.Warehouse end as Warehouse,
	|	Items.Account as Account, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.Social as Social, Items.Price as Price, Items.ProducerPrice as ProducerPrice, Items.Capacity as Capacity, 
	|	Items.PurchaseOrder as PurchaseOrder, Items.VendorInvoice as VendorInvoice,
	|	Items.Package as VendorPackage,"
	+ amount.Amount + " as Amount,"
	+ amount.ContractAmount + " as ContractAmount,"
	+ amount.ContractVAT + " as ContractVAT,"
	+ amount.Total + " as Total,"
	+ amount.ContractTotal + " as ContractTotal
	|into Items
	|from Document.VendorReturn.Items as Items
	|where Items.Ref = &Ref
	|index by Items.Item, Items.Feature, Items.Series, Items.RowKey, Items.DocumentOrder, Items.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInvalidRows ( Env )
	
	sqlInvoiceChanged ( Env );
	sqlExcessQuantity ( Env );
	
EndProcedure

Procedure sqlInvoiceChanged ( Env )

	s = "
	|// ^InvoiceChanged
	|select Items.LineNumber as LineNumber
	|from Items
	|	//
	|	// Receipt
	|	//
	|	left join Document.VendorInvoice.Items as Receipt
	|	on Receipt.Ref = Items.VendorInvoice
	|	and Receipt.Item = Items.Item
	|	and Receipt.Feature = Items.Feature
	|	and Receipt.Series = Items.Series
	|	and Receipt.Package = Items.VendorPackage
	|	and Receipt.Price = Items.Price
	|where Receipt.Ref is null
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlExcessQuantity ( Env )

	s = "
	|// Returns
	|select Returns.VendorInvoice as VendorInvoice, Returns.Item as Item, 
	|	Returns.Feature as Feature, Returns.Series as Series, sum ( Returns.Quantity ) as Quantity
	|into Returns
	|from Document.VendorReturn.Items as Returns
	|where Returns.VendorInvoice in ( select Items.VendorInvoice from Items as Items )
	|and Returns.Ref <> &Ref
	|and Returns.Ref.Posted
	|group by Returns.VendorInvoice, Returns.Item, Returns.Feature, Returns.Series
	|;
	|// ^ExcessQuantity
	|select min ( Items.LineNumber ) as LineNumber, Items.Item as Item, Items.VendorInvoice as VendorInvoice,
	|	sum ( Receipts.Quantity - isnull ( Returns.Quantity, 0 ) ) as QuantityBalance,
	|	sum ( Items.Quantity - Receipts.Quantity - isnull ( Returns.Quantity, 0 ) ) as Quantity
	|from Items as Items
	|	//
	|	// Receipts
	|	//
	|	join Document.VendorInvoice.Items as Receipts
	|	on Receipts.Ref = Items.VendorInvoice
	|	and Receipts.Item = Items.Item
	|	and Receipts.Feature = Items.Feature
	|	and Receipts.Series = Items.Series
	|	//
	|	// Returns
	|	//
	|	left join Returns as Returns
	|	on Returns.VendorInvoice = Items.VendorInvoice
	|	and Returns.Item = Items.Item
	|	and Returns.Feature = Items.Feature
	|	and Returns.Series = Items.Series
	|group by Items.Item, Items.VendorInvoice
	|having sum ( Receipts.Quantity ) < sum ( Items.Quantity + isnull ( Returns.Quantity, 0 ) )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlFixedAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|// FixedAssets
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Item.Account as Account, Items.VendorInvoice as VendorInvoice,"
	+ amount.Amount + " as Amount, "
	+ amount.ContractAmount + " as ContractAmount, "
	+ amount.ContractVAT + " as ContractVAT, "
	+ amount.Total + " as Total, "
	+ amount.ContractTotal + " as ContractTotal
	|into FixedAssets
	|from Document.VendorReturn.FixedAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #FixedAssets
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Account as Account, Items.Amount as Amount, Items.ContractAmount as ContractAmount, 
	|	case when isnull ( Balances.AmountBalance, 0 ) < Items.Amount then true else false end as InvalidRow
	|from FixedAssets as Items
	|	//
	|	// Balances
	|	//
	|	left join AccountingRegister.General.Balance ( &Timestamp, Account in ( select Account from FixedAssets ), , ExtDimension1 in ( select Item from FixedAssets ) ) as Balances
	|	on Balances.Account = Items.Account
	|	and Balances.ExtDimension1 = Items.Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlIntangibleAssets ( Env )
	
	amount = Env.AmountFields;
	s = "
	|// IntangibleAssets
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Item.Account as Account, Items.VendorInvoice as VendorInvoice,
	|"
	+ amount.Amount + " as Amount, "
	+ amount.ContractAmount + " as ContractAmount, "
	+ amount.ContractVAT + " as ContractVAT, "
	+ amount.Total + " as Total, "
	+ amount.ContractTotal + " as ContractTotal
	|into IntangibleAssets
	|from Document.VendorReturn.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|;
	|// #IntangibleAssets
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Account as Account, Items.Amount as Amount, Items.ContractAmount as ContractAmount,
	|	case when isnull ( Balances.AmountBalance, 0 ) < Items.Amount then true else false end as InvalidRow
	|from IntangibleAssets as Items
	|	//
	|	// Balances
	|	//
	|	left join AccountingRegister.General.Balance ( &Timestamp, Account in ( select Account from IntangibleAssets ), , ExtDimension1 in ( select Item from IntangibleAssets ) ) as Balances
	|	on Balances.Account = Items.Account
	|	and Balances.ExtDimension1 = Items.Item
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAccounts ( Env )
	
	amount = Env.AmountFields;
	s = "
	|select Accounts.Account as Account, Accounts.Content as Content, Accounts.Currency as Currency,
	|	Accounts.CurrencyAmount as CurrencyAmount, Accounts.Rate as Rate, Accounts.Factor as Factor,
	|	Accounts.Quantity as Quantity, Accounts.Dim1 as Dim1, Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3,
	|	"
	+ amount.Amount + " as Amount, "
	+ amount.ContractAmount + " as ContractAmount, "
	+ amount.ContractVAT + " as ContractVAT, "
	+ amount.Total + " as Total,
	|	Accounts.VendorInvoice as VendorInvoice, Accounts.VAT as VAT, Accounts.VATAccount as VATAccount
	|into Accounts
	|from Document.VendorReturn.Accounts as Accounts
	|where Accounts.Ref = &Ref
	|;
	|// #Accounts
	|select Accounts.Account as Account, Accounts.Content as Content, Accounts.Currency as Currency,
	|	Accounts.CurrencyAmount as CurrencyAmount, Accounts.Rate as Rate, Accounts.Factor as Factor,
	|	Accounts.Quantity as Quantity, Accounts.Dim1 as Dim1, Accounts.Dim2 as Dim2, Accounts.Dim3 as Dim3,
	|	Accounts.Amount as Amount, Accounts.ContractAmount as ContractAmount, Accounts.Total as Total,
	|	Accounts.VendorInvoice as VendorInvoice
	|from Accounts as Accounts
	|";
	Env.Selection.Add ( s );
	
EndProcedure
	
Procedure sqlReserves ( Env )
	
	s = "
	|// SOItems
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, 
	|	Items.DocumentOrderRowKey as RowKey, Items.Warehouse as Warehouse, Items.Quantity as Quantity
	|into SOItems
	|from Items as Items
	|where Items.DocumentOrder refs Document.SalesOrder
	|and Items.DocumentOrder <> value ( Document.SalesOrder.EmptyRef ) 
	|union all
	|select Items.LineNumber, SOItems.Ref, SOItems.RowKey, Items.Warehouse, Items.Quantity
	|from Items as Items
	|	//
	|	// SOItems
	|	//
	|	join Document.SalesOrder.Items as SOItems
	|	on SOItems.DocumentOrder = Items.PurchaseOrder
	|	and SOItems.DocumentOrderRowKey = Items.RowKey
	|	and SOItems.Reservation = value ( Enum.Reservation.PurchaseOrder )
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|;
	|// IOItems
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, 
	|	Items.DocumentOrderRowKey as RowKey, Items.Warehouse as Warehouse, Items.Quantity as Quantity
	|into IOItems
	|from Items as Items
	|where Items.DocumentOrder refs Document.InternalOrder
	|union all
	|select Items.LineNumber, IOItems.Ref, IOItems.RowKey, Items.Warehouse, Items.Quantity
	|from Items as Items
	|	//
	|	// IOItems
	|	//
	|	join Document.InternalOrder.Items as IOItems
	|	on IOItems.DocumentOrder = Items.PurchaseOrder
	|	and IOItems.DocumentOrderRowKey = Items.RowKey
	|	and IOItems.Reservation = value ( Enum.Reservation.Invoice )
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|;
	|// SOReserves
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, Items.RowKey as RowKey, Items.Warehouse as Warehouse, 
	|	case when Items.Quantity > Balances.QuantityBalance then Balances.QuantityBalance else Items.Quantity end as Quantity
	|into SOReserves
	|from SOItems as Items
	|	//
	|	// Balances
	|	//
	|	join AccumulationRegister.Reserves.Balance ( &Timestamp, 
	|		( DocumentOrder, RowKey ) in ( select DocumentOrder, RowKey from SOItems ) ) as Balances
	|	on Balances.DocumentOrder = Items.DocumentOrder
	|	and Balances.RowKey = Items.RowKey
	|where Balances.QuantityBalance > 0
	|;
	|// IOReserves
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, Items.RowKey as RowKey, Items.Warehouse as Warehouse, 
	|	case when Items.Quantity > Balances.QuantityBalance then Balances.QuantityBalance else Items.Quantity end as Quantity
	|into IOReserves
	|from IOItems as Items
	|	//
	|	// Balances
	|	//
	|	join AccumulationRegister.Reserves.Balance ( &Timestamp, 
	|		( DocumentOrder, RowKey ) in ( select DocumentOrder, RowKey from IOItems ) ) as Balances
	|	on Balances.DocumentOrder = Items.DocumentOrder
	|	and Balances.RowKey = Items.RowKey
	|where Balances.QuantityBalance > 0
	|;
	|// Reserves
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, Items.RowKey as RowKey,
	|	Items.Warehouse as Warehouse, Items.Quantity as Quantity  
	|into Reserves
	|from SOReserves as Items
	|union all
	|select Items.LineNumber as LineNumber, Items.DocumentOrder as DocumentOrder, Items.RowKey as RowKey,
	|	Items.Warehouse as Warehouse, Items.Quantity as Quantity
	|from IOReserves as Items
	|;
	|// ^Reserves
	|select Items.DocumentOrder as DocumentOrder, Items.RowKey as RowKey,
	|	Items.Warehouse as Warehouse, sum ( Items.Quantity ) as Quantity
	|from Reserves as Items
	|group by Items.DocumentOrder, Items.RowKey, Items.Warehouse
	|order by RowKey.Code
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWarehouse ( Env )
	
	s = "
	|// ^Items
	|select Items.Item as Item, Items.Feature as Feature, Items.Series as Series,
	|	Items.Package as Package, Items.Warehouse as Warehouse, 
	|	sum ( Items.QuantityPkg - case when Items.CountPackages then isnull ( Reserves.Quantity, 0 ) / Items.Capacity else isnull ( Reserves.Quantity, 0 ) end ) as Quantity
	|from Items as Items
	|	//
	|	// Reserves 
	|	//
	|	left join Reserves as Reserves
	|	on Reserves.LineNumber = Items.LineNumber
	|group by Items.Item, Items.Feature, Items.Series, Items.Package, Items.Warehouse
	|having sum ( Items.QuantityPkg - case when Items.CountPackages then isnull ( Reserves.Quantity, 0 ) / Items.Capacity else isnull ( Reserves.Quantity, 0 ) end ) > 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlInternalOrders ( Env )
	
	s = "
	|// ^InternalOrders
	|select Items.DocumentOrder as InternalOrder, Items.RowKey as RowKey, 
	|	sum ( Items.Quantity - isnull ( Reserves.Quantity, 0 ) ) as Quantity
	|from Items as Items
	|	//
	|	// Reserves
	|	//
	|	left join Reserves as Reserves
	|	on Reserves.LineNumber = Items.LineNumber
	|where Items.DocumentOrder refs Document.InternalOrder
	|and Items.DocumentOrder <> value ( Document.InternalOrder.EmptyRef )
	|group by Items.DocumentOrder, Items.RowKey
	|having sum ( Items.Quantity - isnull ( Reserves.Quantity, 0 ) ) > 0
	|order by min ( Items.LineNumber )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAllocation ( Env )
	
	s = "
	|// ^Allocation
	|select Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature,
	|	Items.Quantity as Quantity, Items.DocumentOrder as DocumentOrder, 
	|	Items.DocumentOrderRowKey as DocumentOrderRowKey
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.Ref = Items.DocumentOrder
	|	and InternalOrders.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrders.Reservation = value ( Enum.Reservation.Invoice )
	|where Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef )
	|union all
	|select Items.LineNumber, Items.Item, Items.Feature,
	|	Items.Quantity, Items.DocumentOrder, Items.DocumentOrderRowKey
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.DocumentOrder
	|	and SalesOrders.RowKey = Items.DocumentOrderRowKey
	|	and SalesOrders.Reservation = value ( Enum.Reservation.Invoice )
	|where Items.PurchaseOrder = value ( Document.PurchaseOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPurchaseOrders ( Env )
	
	s = "
	|// ^PurchaseOrders
	|select Items.PurchaseOrder as PurchaseOrder, Items.RowKey as RowKey,
	|	Items.Quantity as Quantity, Items.Total as Amount
	|from Items as Items
	|where Items.PurchaseOrder <> value ( Document.PurchaseOrder.EmptyRef )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProvision ( Env )
	
	s = "
	|// ^Provision
	|select Items.PurchaseOrder as PurchaseOrder, Items.RowKey as RowKey, 
	|	Items.Quantity as Quantity
	|from Items as Items
	|	//
	|	// PurchaseOrders
	|	//
	|	join Document.PurchaseOrder.Items as PurchaseOrders
	|	on PurchaseOrders.Ref = Items.PurchaseOrder
	|	and PurchaseOrders.RowKey = Items.RowKey
	|	and PurchaseOrders.Provision = value ( Enum.Provision.Free )
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
	|		select FixedAssets.Amount, FixedAssets.ContractAmount, 0
	|		from FixedAssets as FixedAssets
	|		union all
	|		select IntangibleAssets.Amount, IntangibleAssets.ContractAmount, 0
	|		from IntangibleAssets as IntangibleAssets
	|		union all
	|		select " + fields.VAT + ", " + fields.ContractVAT + ", " + fields.ContractVAT + "
	|		from Document.VendorReturn as Document
	|		where Document.Ref = &Ref ) as Items
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlItemKeys ( Env )
	
	s = "
	|// ItemKeys
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
	|select min ( Items.LineNumber ) as LineNumber, Items.Warehouse as Warehouse, Items.Item as Item, Items.Package as Package, 
	|	Items.Item.Unit as Unit, Items.Feature as Feature, Items.Series as Series, Items.Account as Account, Details.ItemKey as ItemKey, 
	|	sum ( Items.QuantityPkg ) as Quantity, sum ( Items.Amount ) as Amount, sum ( Items.ContractAmount ) as ContractAmount, 
	|	sum ( Items.Quantity ) as Units
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
	|group by Items.Warehouse, Items.Item, Items.Package, Items.Item.Unit, 
	|	Items.Feature, Items.Series, Items.Account, Details.ItemKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCost ( Env )
	
	s = "
	|// ^Cost
	|select Cost.ItemKey as ItemKey, Cost.Lot as Lot, Cost.QuantityBalance as Quantity,
	|	Cost.AmountBalance as Amount
	|from AccumulationRegister.Cost.Balance ( &Timestamp, ItemKey in ( select ItemKey from ItemKeys ) ) as Cost
	|order by Cost.Lot.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlVAT ( Env )
	
	amount = Env.AmountFields;
	fields = "VATAccount as Account, " + amount.VAT + " as Amount, " + amount.ContractVAT + " as ContractAmount";
	s = "
	|// #VAT
	|select VAT.Account as Account, sum ( VAT.Amount ) as Amount, sum ( VAT.ContractAmount ) as ContractAmount
	|from (
	|	select " + fields + "
	|	from Document.VendorReturn.Items as Items
	|	where Items.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorReturn.FixedAssets as FixedAssets
	|	where FixedAssets.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Document.VendorReturn.IntangibleAssets as IntangibleAssets
	|	where IntangibleAssets.Ref = &Ref
	|	union all
	|	select " + fields + "
	|	from Accounts as Accounts
	|	) as VAT
	|group by VAT.Account
	|having sum ( VAT.Amount ) > 0
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

Procedure getTables ( Env )
	
	fields = Env.Fields;
	Env.Q.SetParameter ( "Warehouse", fields.Warehouse );
	Env.Q.SetParameter ( "Timestamp", fields.Timestamp );
	Env.Q.SetParameter ( "Rate", fields.Rate );
	Env.Q.SetParameter ( "Factor", fields.Factor );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", Env.Q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure

Function invalidRows ( Env )
	
	if ( invoiceChanged ( Env )
		or excessQuantity ( Env ) ) then
		return true;				
	endif;
	return false;
	
EndFunction

Function invoiceChanged ( Env )
	
	table = SQL.Fetch ( Env, "$InvoiceChanged" );
	ref = Env.Ref;
	for each row in table do
		Output.VendorReturnInvoiceChanged ( , Output.Row ( "Items", row.LineNumber, "Item" ), ref );
	enddo;
	return table.Count () > 0; 
	
EndFunction

Function excessQuantity ( Env )
	
	table = SQL.Fetch ( Env, "$ExcessQuantity" );
	msg = new Structure ( "Item, Quantity, VendorInvoice, QuantityBalance, Price" );
	ref = Env.Ref;
	for each row in table do
		FillPropertyValues ( msg, row );
		Output.VendorReturnExcessQuantity ( msg, Output.Row ( "Items", row.LineNumber, "Item" ), ref );
	enddo;
	return table.Count () > 0;
	
EndFunction

Procedure makeItems ( Env )
	
	table = SQL.Fetch ( Env, "$Items" );
	Env.Insert ( "ItemsExist", table.Count () > 0 );
	recordset = Env.Registers.Items;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = period;
		movement.Item = row.Item;
		movement.Feature = row.Feature;
		movement.Series = row.Series;
		movement.Warehouse = row.Warehouse;
		movement.Package = row.Package;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function makeFixedAssets ( Env )
	
	ref = Env.Ref;
	msg = Posting.Msg ( Env, "Item" );
	error = false;
	table = Env.FixedAssets; 
	fields = Env.Fields;
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.FixedAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			msg.Item = row.Item;
			Output.AssetBalanceError ( msg, Output.Row ( "FixedAssets", row.LineNumber, "Item" ), ref );
			continue;
		endif; 
		p.AccountDr = row.Account;
		p.QuantityDr = - 1;
		p.Amount = - row.Amount;
		p.DimDr1 = row.Item;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = - row.ContractAmount;
		GeneralRecords.Add ( p );
	enddo;
	return not error;
	
EndFunction

Function makeIntangibleAssets ( Env )
	
	ref = Env.Ref;
	msg = Posting.Msg ( Env, "Item" );
	error = false;
	table = Env.IntangibleAssets; 
	fields = Env.Fields;
	vendorAccount = fields.VendorAccount;
	vendor = fields.Vendor;
	contract = fields.Contract;
	currency = fields.ContractCurrency;
	p = GeneralRecords.GetParams ();
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Operation = Enums.Operations.IntangibleAssetsReceipt;
	p.Recordset = Env.Registers.General;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			msg.Item = row.Item;
			Output.AssetBalanceError ( msg, Output.Row ( "IntangibleAssets", row.LineNumber, "Item" ), ref );
			continue;
		endif;
		p.AccountDr = row.Account;
		p.QuantityDr = - 1;
		p.Amount = - row.Amount;
		p.DimDr1 = row.Item;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = - row.ContractAmount;
		GeneralRecords.Add ( p );
	enddo;
	return not error;
	
EndFunction

Procedure makeAccounts ( Env )
	
	table = Env.Accounts; 
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
		p.Amount = - row.Amount;
		p.QuantityDr = - row.Quantity;
		p.DimDr1 = row.Dim1;
		p.DimDr2 = row.Dim2;
		p.DimDr3 = row.Dim3;
		p.CurrencyDr = row.Currency;
		p.CurrencyAmountDr = - row.CurrencyAmount;
		p.AccountCr = vendorAccount;
		p.DimCr1 = vendor;
		p.DimCr2 = contract;
		p.CurrencyCr = currency;
		p.CurrencyAmountCr = - row.ContractAmount;
		GeneralRecords.Add ( p );
	enddo;
	
EndProcedure 

Procedure makeInternalOrders ( Env )
	
	table = SQL.Fetch ( Env, "$InternalOrders" );
	recordset = Env.Registers.InternalOrders;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = period;
		movement.InternalOrder = row.InternalOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeAllocation ( Env )
	
	table = SQL.Fetch ( Env, "$Allocation" );
	recordset = Env.Registers.Allocation;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = period;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makeReserves ( Env )

	table = SQL.Fetch ( Env, "$Reserves" );
	Env.Insert ( "ReservesExist", table.Count () > 0 );
	recordset = Env.Registers.Reserves;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddExpense ();
		movement.Period = period;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.RowKey;
		movement.Warehouse = row.Warehouse;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Procedure makePurchaseOrders ( Env )

	table = SQL.Fetch ( Env, "$PurchaseOrders" );
	recordset = Env.Registers.PurchaseOrders;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = period;
		movement.PurchaseOrder = row.PurchaseOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	
EndProcedure

Procedure makeProvision ( Env )
	
	table = SQL.Fetch ( Env, "$Provision" );
	recordset = Env.Registers.Provision;
	period = Env.Fields.Date;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = period;
		movement.DocumentOrder = row.PurchaseOrder;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function makeValues ( Env )
	
	lockCost ( Env );
	if ( not makeCost ( Env ) ) then
		return false;		
	endif;
	commitCost ( Env );
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

Function makeCost ( Env )
	
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	costs = SQL.Fetch ( Env, "$Cost" );
	recordset = Env.Registers.Cost;
	filter = new Structure ( "ItemKey" );
	period = Env.Fields.Date;
	column = ? ( Options.Packages (), "QuantityPkg", "Quantity" );
	ref = Env.Ref;
	error = false;
	for each row in table do
		itemKey = row.ItemKey;
		filter.ItemKey = itemKey;
		foundedRows = costs.FindRows ( filter );
		requiredAmount = row.Amount;
		requiredQuantity = row.Quantity;
		quantityBalance = 0;
		for each foundedRow in foundedRows do
			if ( requiredQuantity = 0 )
				and ( requiredAmount = 0 ) then
				break;						
			endif;
			availableQuantity = foundedRow.Quantity;
			availableAmount = foundedRow.Amount;
			quantity = Min ( requiredQuantity, availableQuantity );
			amount = Min ( requiredAmount, availableAmount );
			requiredQuantity = requiredQuantity - quantity;
			requiredAmount = requiredAmount - amount;
			quantityBalance = quantityBalance + availableQuantity;
			record = recordset.AddExpense ();
			record.Period = period;
			record.ItemKey = itemKey;
			record.Lot = foundedRow.Lot;
			record.Quantity = quantity;
			record.Amount = amount;
		enddo;
		if ( requiredQuantity > 0 ) then
			error = true;
			msg = Posting.Msg ( Env, "Warehouse, Item, QuantityBalance, Quantity" );
			msg.Item = row.Item;
			msg.Warehouse = row.Warehouse;
			msg.QuantityBalance = Conversion.NumberToQuantity ( quantityBalance, row.Package );
			msg.Quantity = Conversion.NumberToQuantity ( requiredQuantity, row.Package );
			Output.ItemsCostBalanceError ( msg, Output.Row ( "Items", row.LineNumber, column ), ref );
		endif; 
	enddo;
	return not error;

EndFunction

Procedure commitCost ( Env )
	
	if ( Env.RestoreCost ) then
		cleanCost ( Env );
	endif;
	table = SQL.Fetch ( Env, "$ItemsAndKeys" );
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.AccountCr = fields.VendorAccount;
	p.Operation = Enums.Operations.ItemsReturn;
	p.DimCr1 = fields.Vendor;
	p.DimCr2 = fields.Contract;
	p.CurrencyCr = fields.ContractCurrency;
	p.Recordset = Env.Registers.General;
	for each row in Table do
		p.AccountDr = row.Account;
		p.Amount = - row.Amount;
		p.QuantityDr = - row.Units;
		p.DimDr1 = row.Item;
		p.DimDr2 = row.Warehouse;
		p.CurrencyAmountCr = - row.ContractAmount;
		GeneralRecords.Add ( p );
	enddo;

EndProcedure

Procedure cleanCost ( Env )
	
	recordset = Env.Registers.General;
	recordset.Read ();
	i = recordset.Count () - 1;
	while ( i >= 0 ) do
		if ( recordset [ i ].Operation = Enums.Operations.ItemsReturn ) then
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

Procedure makeVAT ( Env )
	
	table = Env.VAT; 
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
	for each row in table do
		p.CurrencyAmountCr = - row.ContractAmount;
		p.AccountDr = row.Account;
		p.Amount = - row.Amount;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure

Function checkBalances ( Env )
	
	registers = Env.Registers;
	items = registers.Items;
	if ( Env.ItemsExist
		and Env.CheckBalances ) then
		items.LockForUpdate = true;
		items.Write ();
		Shortage.SqlItems ( Env );
	else
		items.Write = true;
	endif;
	reserves = registers.Reserves;
	if ( Env.ReservesExist
		and Env.CheckBalances ) then
		reserves.LockForUpdate = true;
		reserves.Write ();
		Shortage.SqlReserves ( Env );
	else
		reserves.Write = true;
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
	if ( Env.ReservesExist ) then
		table = SQL.Fetch ( Env, "$ShortageReserves" );
		if ( table.Count () > 0 ) then
			Shortage.Reserves ( Env, table );
			return false;
		endif; 
	endif;
	return true;
	
EndFunction

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
	
Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.General.Write = true;
	registers.Cost.Write = true;
	if ( not Env.RestoreCost ) then
		registers.VendorDebts.Write = true;
		registers.Allocation.Write = true;
		registers.Provision.Write = true;
		registers.PurchaseOrders.Write = true;
		registers.InternalOrders.Write = true;
		registers.Reserves.Write = true;				
	endif; 
	
EndProcedure

#endregion

#endif