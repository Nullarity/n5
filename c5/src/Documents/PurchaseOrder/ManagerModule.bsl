#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.PurchaseOrder.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	if ( not checkDeliveryDateRows ( Env ) ) then
		return false;
	endif; 
	RunDebts.FromOrder ( Env );
	makePurchaseOrders ( Env );
	makeProvision ( Env );
	if ( not makeAllocations ( Env ) ) then
		return false;
	endif; 
	if ( not checkBalances ( Env ) ) then
		return false;
	endif; 
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )
	
	sqlFields ( Env );
	sqlItems ( Env );
	sqlWrongDelivery ( Env );
	sqlPurchaseOrders ( Env );
	sqlPayments ( Env );
	sqlProvision ( Env );
	sqlAllocation ( Env );
	getTables ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Amount as Amount, Documents.Contract as Contract
	|from Document.PurchaseOrder as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure
 
Procedure sqlItems ( Env )
	
	s = "
	|select ""Items"" as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature, Items.Quantity as Quantity,
	|	Items.Amount as Amount, Items.RowKey as RowKey, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	Items.Provision as Provision, Items.DeliveryDate as DeliveryDate
	|into Items
	|from Document.PurchaseOrder.Items as Items
	|where Items.Ref = &Ref
	|index by Items.DocumentOrder, Items.DocumentOrderRowKey
	|;
	|select ""Services"" as Table, Services.LineNumber as LineNumber, Services.Item as Item, Services.Feature as Feature,
	|	Services.Quantity as Quantity, Services.Amount as Amount, Services.RowKey as RowKey, Services.DocumentOrder as DocumentOrder,
	|	Services.DocumentOrderRowKey as DocumentOrderRowKey, Services.DeliveryDate as DeliveryDate
	|into Services
	|from Document.PurchaseOrder.Services as Services
	|where Services.Ref = &Ref
	|index by Services.DocumentOrder, Services.DocumentOrderRowKey
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlWrongDelivery ( Env )
	
	s = "
	|// #WrongDelivery
	|select Items.Table as Table, Items.LineNumber as LineNumber, SalesOrders.DeliveryDate as DeliveryDate
	|from Items as Items
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Items as SalesOrders
	|	on SalesOrders.Ref = Items.DocumentOrder
	|	and SalesOrders.RowKey = Items.DocumentOrderRowKey
	|	and SalesOrders.DeliveryDate < Items.DeliveryDate
	|union all
	|select Services.Table, Services.LineNumber, SalesOrders.DeliveryDate
	|from Services as Services
	|	//
	|	// SalesOrders
	|	//
	|	join Document.SalesOrder.Services as SalesOrders
	|	on SalesOrders.Ref = Services.DocumentOrder
	|	and SalesOrders.RowKey = Services.DocumentOrderRowKey
	|	and SalesOrders.DeliveryDate < Services.DeliveryDate
	|union all
	|select Items.Table, Items.LineNumber, InternalOrders.DeliveryDate
	|from Items as Items
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Items as InternalOrders
	|	on InternalOrders.Ref = Items.DocumentOrder
	|	and InternalOrders.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrders.DeliveryDate < Items.DeliveryDate
	|union all
	|select Services.Table, Services.LineNumber, InternalOrders.DeliveryDate
	|from Services as Services
	|	//
	|	// InternalOrders
	|	//
	|	join Document.InternalOrder.Services as InternalOrders
	|	on InternalOrders.Ref = Services.DocumentOrder
	|	and InternalOrders.RowKey = Services.DocumentOrderRowKey
	|	and InternalOrders.DeliveryDate < Services.DeliveryDate
	|";
	Env.Selection.Add ( s );
	
EndProcedure 
 
Procedure sqlPurchaseOrders ( Env )
	
	s = "
	|// ^PurchaseOrders
	|select Items.LineNumber as LineNumber, Items.RowKey as RowKey, Items.Quantity as Quantity, Items.Amount as Amount
	|from Items as Items
	|union all
	|select Services.LineNumber, Services.RowKey, Services.Quantity, Services.Amount
	|from Services as Services
	|order by LineNumber
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlPayments ( Env )
	
	s = "
	|// ^Payments
	|select case when Payments.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Payments.PaymentDate end as PaymentDate,
	|	Payments.Option as Option, Payments.Amount as Amount, PaymentDetails.PaymentKey as PaymentKey
	|from Document.PurchaseOrder.Payments as Payments
	|	//
	|	// PaymentDetails
	|	//
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.Option = Payments.Option
	|	and PaymentDetails.Date = case when Payments.PaymentDate = datetime ( 1, 1, 1 ) then datetime ( 3999, 12, 31 ) else Payments.PaymentDate end
	|where Payments.Ref = &Ref
	|and Payments.Amount <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlProvision ( Env )
	
	s = "
	|// ^Provision
	|select Items.RowKey as RowKey, Items.Quantity as Quantity
	|from Items as Items
	|where Items.Provision = value ( Enum.Provision.Free )
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAllocation ( Env )
	
	s = "
	|select Items.Table as Table, Items.LineNumber as LineNumber, Items.Item as Item, Items.Feature as Feature,
	|	Items.Quantity as Quantity, Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey
	|into Allocation
	|from Items as Items
	|where Items.DocumentOrder <> undefined
	|union all
	|select Services.Table, Services.LineNumber, Services.Item, Services.Feature, Services.Quantity, Services.DocumentOrder, Services.DocumentOrderRowKey
	|from Services as Services
	|where Services.DocumentOrder <> undefined
	|index by Items.DocumentOrder, Items.DocumentOrderRowKey
	|;
	|select distinct Allocation.DocumentOrder as DocumentOrder
	|into InternalOrders
	|from Allocation as Allocation
	|where DocumentOrder refs Document.InternalOrder
	|index by Allocation.DocumentOrder
	|;
	|// ^Allocation
	|select Items.LineNumber as LineNumber, Items.Table as Table, Items.Quantity as Quantity,
	|	Items.DocumentOrder as DocumentOrder, Items.DocumentOrderRowKey as DocumentOrderRowKey,
	|	case when SalesOrderItems.Item is null
	|		and SalesOrderServices.Item is null
	|		and InternalOrderItems.Item is null
	|		and InternalOrderServices.Item is null
	|	then true
	|	else false
	|	end as InvalidRow
	|from Allocation as Items
	|	//
	|	// SalesOrderItems
	|	//
	|	left join Document.SalesOrder.Items as SalesOrderItems
	|	on SalesOrderItems.Ref = Items.DocumentOrder
	|	and SalesOrderItems.RowKey = Items.DocumentOrderRowKey
	|	and SalesOrderItems.Item = Items.Item
	|	and SalesOrderItems.Feature = Items.Feature
	|	//
	|	// SalesOrderServices
	|	//
	|	left join Document.SalesOrder.Services as SalesOrderServices
	|	on SalesOrderServices.Ref = Items.DocumentOrder
	|	and SalesOrderServices.RowKey = Items.DocumentOrderRowKey
	|	and SalesOrderServices.Item = Items.Item
	|	and SalesOrderServices.Feature = Items.Feature
	|	//
	|	// InternalOrderItems
	|	//
	|	left join Document.InternalOrder.Items as InternalOrderItems
	|	on InternalOrderItems.Ref = Items.DocumentOrder
	|	and InternalOrderItems.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrderItems.Item = Items.Item
	|	and InternalOrderItems.Feature = Items.Feature
	|	//
	|	// InternalOrderServices
	|	//
	|	left join Document.InternalOrder.Services as InternalOrderServices
	|	on InternalOrderServices.Ref = Items.DocumentOrder
	|	and InternalOrderServices.RowKey = Items.DocumentOrderRowKey
	|	and InternalOrderServices.Item = Items.Item
	|	and InternalOrderServices.Feature = Items.Feature
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getTables ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 
 
Function checkDeliveryDateRows ( Env )
	
	if ( Env.WrongDelivery.Count () = 0 ) then
		return true;
	endif; 
	p = new Structure ( "DeliveryDate" );
	ref = Env.Ref;
	for each row in Env.WrongDelivery do
		p.DeliveryDate = row.DeliveryDate;
		Output.IncorrectDeliveryDate ( p, Output.Row ( row.Table, row.LineNumber, "DeliveryDate" ), ref );
	enddo; 
	return false;
	
EndFunction 

Procedure makePurchaseOrders ( Env )

	table = SQL.Fetch ( Env, "$PurchaseOrders" );
	recordset = Env.Registers.PurchaseOrders;
	date = Env.Fields.Date;
	ref = Env.Ref;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = date;
		movement.PurchaseOrder = ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
		movement.Amount = row.Amount;
	enddo; 
	
EndProcedure

Procedure makeProvision ( Env )

	table = SQL.Fetch ( Env, "$Provision" );
	recordset = Env.Registers.Provision;
	for each row in table do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.DocumentOrder = Env.Ref;
		movement.RowKey = row.RowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	
EndProcedure

Function makeAllocations ( Env )

	error = false;
	table = SQL.Fetch ( Env, "$Allocation" );
	Env.Insert ( "AllocationExists", table.Count () > 0 );
	recordset = Env.Registers.Allocation;
	date = Env.Fields.Date;
	for each row in table do
		if ( row.InvalidRow ) then
			error = true;
			Output.DocumentOrderItemsNotValid ( new Structure ( "DocumentOrder", row.DocumentOrder ), Output.Row ( row.Table, row.LineNumber, "Item" ), Env.Ref );
			continue;
		endif; 
		movement = recordset.AddExpense ();
		movement.Period = date;
		movement.DocumentOrder = row.DocumentOrder;
		movement.RowKey = row.DocumentOrderRowKey;
		movement.Quantity = row.Quantity;
	enddo; 
	return not error;
	
EndFunction

Function checkBalances ( Env )
	
	register = Env.Registers.Allocation;
	if ( Env.AllocationExists ) then
		register.LockForUpdate = true;
		register.Write ();
		Shortage.SqlProvision ( Env );
		SQL.Prepare ( Env );
		SQL.Unload ( Env );
		table = SQL.Fetch ( Env, "$ShortageProvision" );
		if ( table.Count () > 0 ) then
			Shortage.Provision ( Env, table );
			return false;
		endif; 
	else
		register.Write = true;
	endif; 
	return true;
	
EndFunction

Procedure flagRegisters ( Env )
	
	registers = Env.Registers;
	registers.VendorDebts.Write = true;
	registers.PurchaseOrders.Write = true;
	registers.Provision.Write = true;
	
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
	putMemo ( Params, Env );
	return true;
	
EndFunction
 
Procedure setPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.PageOrientation = PageOrientation.Portrait;
	tabDoc.FitToPage = true;
	
EndProcedure 

Procedure getPrintData ( Params, Env )
	
	sqlPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPrintData ( Env )
	
	s = "
	|// @Fields
	|select Document.Number as Number, Document.Date as Date, Document.Company.FullDescription as Company,
	|	Document.Company.Discounts as Discounts, Document.DeliveryDate as DeliveryDate,
	|	Document.Company.PaymentAddress.Presentation as Address, Document.Manager.Description as Manager,
	|	Document.Vendor.FullDescription as Vendor, Document.Warehouse.Address.Presentation as ShippingAddress,
	|	Document.Contract.CustomerTerms.Description as Terms, Document.Taxable as Taxable, Document.TaxRate as TaxRate,
	|	Document.Amount as Amount, Document.Tax as Tax, Document.Amount - Document.Tax as Subtotal,
	|	Document.Discount as Discount, Document.GrossAmount as GrossAmount, Document.Currency.Description as Currency,
	|	Document.Memo as Memo
	|from Document.PurchaseOrder as Document
	|where Document.Ref = &Ref
	|;
	|// #Items
	|select Items.Item.Description as Item, Items.Feature.Description as Feature, Items.QuantityPkg as Quantity,
	|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Package,
	|	Items.Price as Price, Items.DiscountRate as DiscountRate, Items.Amount as Amount, Items.DeliveryDate as DeliveryDate
	|from Document.PurchaseOrder.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|;
	|// #Services
	|select Services.Description as Item, Services.Feature.Description as Feature, Services.Quantity as Quantity,
	|	Services.Item.Unit.Code as Package, Services.Price as Price, Services.DiscountRate as DiscountRate,
	|	Services.Amount as Amount, Services.DeliveryDate as DeliveryDate
	|from Document.PurchaseOrder.Services as Services
	|where Services.Ref = &Ref
	|order by Services.LineNumber
	|;
	|// #Taxes
	|select Taxes.Tax.Print as Tax, Taxes.Percent as Percent, Taxes.Amount as Amount
	|from Document.PurchaseOrder.Taxes as Taxes
	|where Taxes.Ref = &Ref
	|order by Taxes.LineNumber
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
	tabDoc = Params.TabDoc;
	fields = Env.Fields;
	if ( fields.Discounts ) then
		header = t.GetArea ( "TableDiscount" );
		area = t.GetArea ( "RowDiscount" );
	else
		header = t.GetArea ( "Table" );
		area = t.GetArea ( "Row" );
	endif;
	header.Parameters.Fill ( fields );
	tabDoc.Put ( header );
	Print.Repeat ( tabDoc );
	table = Env.Items;
	CollectionsSrv.Join ( table, Env.Services );
	accuracy = Application.Accuracy ();
	lineNumber = 0;
	p = area.Parameters;
	for each row in table do
		lineNumber = lineNumber + 1;
		p.Fill ( row );
		p.LineNumber = lineNumber;
		p.Item = Print.FormatItem ( row.Item, row.Package, row.Feature );
		p.Quantity = Format ( row.Quantity, accuracy );
		tabDoc.Put ( area );
	enddo; 
	
EndProcedure

Procedure putFooter ( Params, Env )
	
	t = Env.T;
	fields = Env.Fields;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "Footer" );
	tabDoc.Put ( area );
	if ( fields.Discounts ) then
		area = t.GetArea ( "Discount" );
		area.Parameters.Fill ( fields );
		tabDoc.Put ( area );
	endif; 
	if ( fields.Taxable ) then
		area = t.GetArea ( "Subtotal" );
		area.Parameters.SubTotal = fields.SubTotal;
		tabDoc.Put ( area );
		area = t.GetArea ( "Tax" );
		p = area.Parameters;
		for each row in Env.Taxes do
			p.Tax = row.Tax;
			p.Rate = Format ( row.Percent, "NZ=" );
			p.Amount = row.Amount;
			tabDoc.Put ( area );
		enddo; 
	endif; 
	area = t.GetArea ( "Total" );
	area.Parameters.Fill ( fields );
	tabDoc.Put ( area );
	
EndProcedure

Procedure putMemo ( Params, Env )
	
	area = Env.T.GetArea ( "Memo" );
	area.Parameters.Fill ( Env.Fields );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif