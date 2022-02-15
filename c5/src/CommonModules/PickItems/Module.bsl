
&AtClient
Procedure Open ( Form, Params ) export
	
	OpenForm ( "DataProcessor.Items.Form", new Structure ( "Source", Params ), Form );
	
EndProcedure

&AtServer
Function GetParams ( Form ) export
	
	object = Form.Object;
	ref = object.Ref;
	p = new Structure ();
	p.Insert ( "Ref", ref );
	p.Insert ( "Type", getType ( ref ) );
	p.Insert ( "Company", getCompany ( object ) );
	p.Insert ( "Date", getDate ( object ) );
	p.Insert ( "Warehouse", getWarehouse ( p, object ) );
	p.Insert ( "Customer", getCustomer ( p, object ) );
	p.Insert ( "Contract", getContract ( p, object ) );
	p.Insert ( "Vendor", getVendor ( p, object ) );
	p.Insert ( "Currency", getCurrency ( p, object ) );
	p.Insert ( "DeliveryDate", getDeliveryDate ( p, object ) );
	p.Insert ( "Prices", getPrices ( p, object ) );
	p.Insert ( "Discounts", getDiscounts ( p, object ) );
	p.Insert ( "ShowPrice", getShowPrice ( p, object ) );
	p.Insert ( "ShowAmount", getShowAmount ( p ) );
	p.Insert ( "ItemsOnly", getItemsOnly ( p ) );
	p.Insert ( "Keys", getKeys ( p ) );
	p.Insert ( "VATUse", getVATUse ( p, object ) );
	p.Insert ( "Filter", getFilter ( p, object ) );
	return p;
	
EndFunction 

&AtServer
Function getType ( Ref )
	
	result = new Structure ();
	type = TypeOf ( Ref );
	pickers = new Array ();
	pickers.Add ( "Quote" );
	pickers.Add ( "SalesOrder" );
	pickers.Add ( "InternalOrder" );
	pickers.Add ( "VendorBill" );
	pickers.Add ( "Bill" );
	pickers.Add ( "ProductionOrder" );
	pickers.Add ( "PurchaseOrder" );
	pickers.Add ( "VendorInvoice" );
	pickers.Add ( "Production" );
	pickers.Add ( "Invoice" );
	pickers.Add ( "Transfer" );
	pickers.Add ( "WriteOff" );
	pickers.Add ( "ReceiveItems" );
	pickers.Add ( "Assembling" );
	pickers.Add ( "Disassembling" );
	pickers.Add ( "InvoiceRecord" );
	pickers.Add ( "ExpenseReport" );
	pickers.Add ( "TimeEntry" );
	pickers.Add ( "Sale" );
	for each name in pickers do
		result.Insert ( name, type = Type ( "DocumentRef." + name ) );
	enddo; 
	return result;
	
EndFunction 

&AtServer
Function getCompany ( Object )
	
	return Object.Company;
	
EndFunction 

&AtServer
Function getDate ( Object )
	
	return Periods.GetBalanceDate ( Object );
	
EndFunction 

&AtServer
Function getWarehouse ( Params, Object )
	
	type = Params.Type;
	if ( type.Transfer ) then
		return Object.Sender;
	elsif ( type.InvoiceRecord ) then
		return Object.LoadingPoint;
	else
		return Object.Warehouse;
	endif; 
	
EndFunction 

&AtServer
Function getCustomer ( Params, Object )
	
	type = Params.Type;
	if ( type.SalesOrder
		or type.Quote
		or type.Bill
		or type.Invoice ) then
		return Object.Customer;
	endif; 

EndFunction 

&AtServer
Function getContract ( Params, Object )
	
	type = Params.Type;
	if ( type.SalesOrder
		or type.Quote
		or type.Bill
		or type.Invoice
		or type.PurchaseOrder
		or type.VendorBill
		or type.VendorInvoice ) then
		return Object.Contract;
	endif; 

EndFunction 

&AtServer
Function getVendor ( Params, Object )
	
	type = Params.Type;
	if ( type.PurchaseOrder
		or type.VendorBill
		or type.VendorInvoice ) then
		return Object.Vendor;
	endif; 

EndFunction 

&AtServer
Function getCurrency ( Params, Object )
	
	type = Params.Type;
	if ( type.Assembling
		or type.Disassembling
		or type.TimeEntry
		or type.ProductionOrder
		or type.Production
		or type.Sale ) then
		return undefined;
	else
		return Object.Currency;
	endif;

EndFunction 

&AtServer
Function getDeliveryDate ( Params, Object )
	
	type = Params.Type;
	if ( type.SalesOrder
		or type.Quote
		or type.PurchaseOrder
		or type.InternalOrder ) then
		return Object.DeliveryDate;
	endif; 

EndFunction 

&AtServer
Function getPrices ( Params, Object )
	
	type = Params.Type;
	if ( type.Assembling
		or type.Disassembling
		or type.TimeEntry
		or type.ProductionOrder
		or type.Production ) then
		return undefined;
	else
		return Object.Prices;
	endif;

EndFunction 

&AtServer
Function getDiscounts ( Params, Object )
	
	type = Params.Type;
	company = Params.Company;
	if ( type.SalesOrder
		or type.Invoice
		or type.Bill
		or type.Quote
		or type.Sale ) then
		return Options.Discounts ( company );
	elsif ( type.PurchaseOrder
		or type.VendorInvoice
		or type.VendorBill ) then
		return Options.VendorDiscounts ( company );
	else
		return false;
	endif; 
	
EndFunction 

&AtServer
Function getShowPrice ( Params, Object )
	
	type = Params.Type;
	if ( type.Transfer
		or type.WriteOff ) then
		return Object.ShowPrices;
	elsif ( type.Assembling
		or type.Disassembling
		or type.TimeEntry
		or type.ProductionOrder
		or type.Production ) then
		return false;
	else
		return true;
	endif; 
	
EndFunction

&AtServer
Function getShowAmount ( Params )
	
	type = Params.Type;
	if ( type.Assembling
		or type.Disassembling
		or type.TimeEntry
		or type.ProductionOrder
		or type.Production ) then
		return false;
	else
		return true;
	endif; 
	
EndFunction

&AtServer
Function getItemsOnly ( Params )
	
	type = Params.Type;
	if ( type.Transfer
		or type.WriteOff
		or type.ReceiveItems
		or type.Assembling
		or type.Disassembling
		or type.TimeEntry
		or type.Sale ) then
		return true;
	else
		return false;
	endif; 
	
EndFunction 

&AtServer
Function getKeys ( Params )
	
	type = Params.Type;
	if ( type.SalesOrder
		or type.InternalOrder ) then
		itemKeys = "Feature, DeliveryDate, DiscountRate, DocumentOrder, DocumentOrderRowKey, Item, Package, Price, Prices, Reservation, Stock, VATCode";
		serviceKeys = "Feature, DeliveryDate, Department, Performer, Item, Price, Prices, Description, DiscountRate, VATCode";
	elsif ( type.PurchaseOrder ) then
		itemKeys = "Feature, Provision, DeliveryDate, DiscountRate, DocumentOrder, DocumentOrderRowKey, Item, Package, Price, Prices, VATCode";
		serviceKeys = "Feature, DeliveryDate, DiscountRate, DocumentOrder, DocumentOrderRowKey, Item, Price, Prices, Description, VATCode";
	elsif ( type.ProductionOrder ) then
		itemKeys = "Feature, Provision, DeliveryDate, DocumentOrder, DocumentOrderRowKey, Item, Package";
		serviceKeys = "Feature, DeliveryDate, DocumentOrder, DocumentOrderRowKey, Item, Description";
	elsif ( type.Production ) then
		itemKeys = "Feature, Series, DocumentOrder, DocumentOrderRowKey, Item, Package";
		serviceKeys = "Feature, DocumentOrder, DocumentOrderRowKey, Item, Description";	
	elsif ( type.Quote
		or type.Bill
		or type.Invoice
		or type.VendorBill
		or type.VendorInvoice ) then
		itemKeys = "Feature, Series, DiscountRate, Item, Package, Price, Prices, VATCode";
		serviceKeys = "Feature, DiscountRate, Item, Price, Prices, Description, VATCode";
	elsif ( type.Transfer
		or type.WriteOff ) then
		itemKeys = "Feature, Item, Package, Price, Prices, Series, TaxCode, DocumentOrder, RowKey";
		serviceKeys = "";
	elsif ( type.TimeEntry ) then
		itemKeys = "Feature, Item, Package, Series";
		serviceKeys = "";
	elsif ( type.Quote
		or type.Bill
		or type.Invoice
		or type.VendorBill
		or type.VendorInvoice ) then
		itemKeys = "Feature, DiscountRate, Item, Package, Price, VATCode";
		serviceKeys = "";
	else
		itemKeys = "Feature, Item, Package, Price, Series";
		serviceKeys = "";
	endif;
	return new Structure ( "ItemKeys, ServiceKeys", itemKeys, serviceKeys );
	
EndFunction 

&AtServer
Function getVATUse ( Params, Object )
	
	type = Params.Type;
	if ( type.Assembling
		or type.ProductionOrder
		or type.Disassembling
		or type.Production
		or type.TimeEntry ) then
		return 0;
	else
		return Object.VATUse;
	endif; 
	
EndFunction

&AtServer
Function getFilter ( Params, Object )
	
	type = Params.Type;
	if ( type.Sale
		or type.Invoice
		or type.Transfer
		or type.WriteOff
		or type.Assembling
		or type.Disassembling
	 ) then
		return Enums.Filter.Available;
	else
		return Enums.Filter.None;
	endif; 
	
EndFunction