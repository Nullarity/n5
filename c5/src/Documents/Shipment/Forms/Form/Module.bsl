&AtServer
var Env;
&AtServer
var ViewSalesOrders;
&AtServer
var ViewInvoices;
&AtClient
var ItemsRow;
&AtClient
var ServicesRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	SetPrivilegedMode ( true );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	InvoiceForm.SetContractCurrency ( ThisObject );
	SetPrivilegedMode ( false );
	readStatus ();
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readStatus ()
	
	Status = InformationRegisters.ShipmentStatuses.Get ( new Structure ( "Document", Object.Ref ) ).Status;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Output.InteractiveCreationRestricted ();
		Cancel = true;
		return;
	endif; 
	togglePrices ();
	setAccuracy ();
	setLinks ();
	Options.Company ( ThisObject, Object.Company );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Discount Amount VATUse VAT show ShowPrices;
	|FormStart show Status = Enum.ShipmentPoints.New;
	|FormComplete show Status = Enum.ShipmentPoints.Picking;
	|FormWrite show Status <> Enum.ShipmentPoints.Finish;
	|FormWrite FormStart FormComplete enable PickupOrderExists <> true;
	|ProcessCompleted show Status = Enum.ShipmentPoints.Finish;
	|PickupOrderAttached show Status <> Enum.ShipmentPoints.Finish and PickupOrderExists;
	|MemoLabel show filled ( Object.Memo );
	|Items Services lock ( PickupOrderExists or Status <> Enum.ShipmentPoints.Picking );
	|Warehouse Memo Number lock ( Status = Enum.ShipmentPoints.Finish or PickupOrderExists );
	|VATItemsPrice ItemsDiscountRate ItemsDiscount ItemsAmount ItemsPrices ItemsVATCode ItemsVAT ItemsTotal ServicesVATCode ServicesVAT ServicesTotal show ShowPrices;
	|VAT ItemsVATCode ItemsVAT ServicesVATCode ServicesVAT show Object.VATUse > 0;
	|ItemsTotal ServicesTotal show Object.VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure togglePrices ()
	
	ShowPrices = Documents.Shipment.ShowPrices ();
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	Options.SetAccuracy ( ThisObject, "ItemsQuantityBack, ItemsQuantityPkgBack", , false );
		
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	q = Env.Q;
	q.SetParameter ( "Ref", Object.Ref );
	q.SetParameter ( "SalesOrder", Object.SalesOrder );
	SQL.Perform ( Env );
	setURLPanel ();
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	// &Ref cannot be empty.
	// The interactive creation of Shipment is forbidden
	selection = Env.Selection;
	meta = Metadata.Documents;
	ViewSalesOrders = AccessRight ( "View", meta.SalesOrder );
	if ( ViewSalesOrders ) then
		s = "
		|// #SalesOrders
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.SalesOrder as Documents
		|where Documents.Ref = &SalesOrder
		|";
		selection.Add ( s );
	endif;
	s = "
	|// #PickupOrders
	|select PickedShipments.PickupOrder as Document, PickedShipments.PickupOrder.Date as Date,
	|	PickedShipments.PickupOrder.Number as Number
	|from InformationRegister.PickedShipments as PickedShipments
	|where PickedShipments.Shipment = &Ref
	|";
	selection.Add ( s );
	ViewInvoices = AccessRight ( "View", meta.Invoice );
	if ( ViewInvoices ) then
		s = "
		|// #Invoices
		|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
		|from Document.Invoice as Documents
		|where Documents.Shipment = &Ref
		|and not Documents.DeletionMark
		|order by Date
		|";
		selection.Add ( s );
	endif; 
	
EndProcedure 

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( ViewSalesOrders ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.SalesOrders, meta.SalesOrder ) );
	endif; 
	if ( ViewInvoices ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Invoices, meta.Invoice ) );
	endif; 
	parts.Add ( URLPanel.DocumentsToURL ( Env.PickupOrders, meta.PickupOrder ) );
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	PickupOrderExists = Env.PickupOrders.Count () > 0;
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Status = Enums.ShipmentPoints.Finish ) then
		if ( Documents.Shipment.CreateInvoice ( CurrentObject ) ) then
			Documents.Shipment.CreateBackOrder ( CurrentObject );
			saveStatus ();
		else
			Cancel = true;
		endif;
	endif; 
	
EndProcedure

&AtServer
Procedure saveStatus ()
	
	r = InformationRegisters.ShipmentStatuses.CreateRecordManager ();
	r.Document = Object.Ref;
	r.Status = Status;
	r.Write ();
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Status" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageShipmentIsSaved (), Object.Ref );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		setItem ( Parameter );
		elsif ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure setItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		Output.ItemNotFound ();
	else
		ItemsRow = rows [ 0 ];
		Items.Items.CurrentRow = ItemsRow.GetID ();
		ItemsRow.Picked = true;
		pickItem ();
	endif; 
	
EndProcedure 

&AtClient
Procedure pickItem ()
	
	ItemsRow.Quantity = ? ( ItemsRow.Picked, ItemsRow.QuantityPlan, 0 );
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	calcQuantityBack ();
	
EndProcedure 

&AtClient
Procedure calcQuantityBack ()
	
	ItemsRow.QuantityBack = ItemsRow.QuantityPlan - ItemsRow.Quantity;
	ItemsRow.QuantityPkgBack = ItemsRow.QuantityBack / ItemsRow.CapacityPlan;
	
EndProcedure 

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure StartPicking ( Command )
	
	startCommand ( Enum.ShipmentCommandsStart () );
	
EndProcedure

&AtClient
Procedure startCommand ( Command )
	
	if ( Command = Enum.ShipmentCommandsStart () ) then
		Output.StartShippingConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = Enum.ShipmentCommandsComplete () ) then
		Output.CompleteShipmentConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	endif; 
	
EndProcedure

&AtClient
Procedure CommandConfirmation ( Answer, Command ) export
	
	if ( Answer <> DialogReturnCode.Yes ) then
		return;
	endif; 
	if ( Command = Enum.ShipmentCommandsStart () ) then
		Status = PredefinedValue ( "Enum.ShipmentPoints.Picking" );
		performCommand ( false );
	elsif ( Command = Enum.ShipmentCommandsComplete () ) then
		Status = PredefinedValue ( "Enum.ShipmentPoints.Finish" );
		performCommand ( true );
	endif;
	
EndProcedure

&AtClient
Procedure performCommand ( CloseForm )
	
	if ( not Write () ) then
		Output.OperationNotPerformed ();
		return;
	endif; 
	if ( CloseForm ) then
		Close ();
	endif;
	
EndProcedure 

&AtClient
Procedure Complete ( Command )
	
	startCommand ( Enum.ShipmentCommandsComplete () );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Scan ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsPickedOnChange ( Item )
	
	pickItem ();
	
EndProcedure

&AtClient
Procedure ItemsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	calcQuantityBack ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Feature", ItemsRow.Feature );
	p.Insert ( "Package", ItemsRow.Package );
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	p.Insert ( "Prices", prices );
	data = getPackageData ( p );
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data = new Structure ();
	data.Insert ( "Capacity", capacity );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	calcQuantityBack ();
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	calcQuantityBack ();

EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	InvoiceForm.CalcTotals ( ThisObject );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Organization", Object.Customer );
	p.Insert ( "Contract", Object.Contract );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ServicesRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getServiceData ( p );
	ServicesRow.Price = data.Price;
	ServicesRow.Description = data.FullDescription;
	ServicesRow.VATCode = data.VAT;
	ServicesRow.VATRate = data.Rate;
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getServiceData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	return data;
	
EndFunction 

&AtClient
Procedure ServicesFeatureOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceService ()
	
	prices = ? ( ServicesRow.Prices.IsEmpty (), Object.Prices, ServicesRow.Prices );
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, Object.Customer, Object.Contract, , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Discount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesDiscountRateOnChange ( Item )
	
	Computations.Discount ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesDiscountOnChange ( Item )
	
	Computations.DiscountRate ( ServicesRow );
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesVATCodeOnChange ( Item )
	
	ServicesRow.VATRate = DF.Pick ( ServicesRow.VATCode, "Rate" );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesVATOnChange ( Item )
	
	Computations.Total ( ServicesRow, Object.VATUse, false );
	
EndProcedure