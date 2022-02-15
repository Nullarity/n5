&AtServer
var Env;
&AtClient
var ItemsRow export;
&AtClient
var ServicesRow export;
&AtServer
var Copy;
&AtServer
var ViewPurchaseOrders;
&AtServer
var ViewVendorInvoices;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	OrderForm.LoadProcess ( ThisObject );
	InvoiceForm.SetLocalCurrency ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setCurrentUser ();
	if ( Object.Ref.IsEmpty () ) then
		Copy = not Parameters.CopyingValue.IsEmpty ();
		InvoiceForm.SetLocalCurrency ( ThisObject );
		DocumentForm.Init ( Object );
		fillNew ();
		OrderForm.InitRoutePoint ( ThisObject );
		if ( Copy ) then
			OrderForm.ResetCopiedFields ( Object );
		endif; 
	endif; 
	setAccuracy ();
	setLinks ();
	ItemPictures.RestoreGallery ( ThisObject );
	Forms.ActivatePage ( ThisObject, "ItemsTable,Services" );
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Rate Factor enable Object.Currency <> LocalCurrency;
	|FormSendForApproval show RoutePoint = Enum.InternalOrderPoints.New and Object.Creator = CurrentUser;
	|FormRework FormReject show inlist ( RoutePoint, Enum.InternalOrderPoints.DepartmentHeadResolution );
	|FormWrite FormSaveAndNew show
	|MyTask
	|and not Editing
	|and inlist ( RoutePoint, Enum.InternalOrderPoints.Rework, Enum.InternalOrderPoints.DepartmentHeadResolution, Enum.InternalOrderPoints.New, Enum.InternalOrderPoints.Delivery );
	|FormReturnToProcess show RoutePoint = Enum.InternalOrderPoints.Rework;
	|FormCommitRejection show RoutePoint = Enum.InternalOrderPoints.Reject;
	|FormCompleteApproval show RoutePoint = Enum.InternalOrderPoints.DepartmentHeadResolution and not Editing;
	|FormModify show
	|CanChange
	|and not Editing
	|and ( ( RoutePoint = Enum.InternalOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Approve )
	|	or ( MyTask and inlist ( RoutePoint, Enum.InternalOrderPoints.Delivery ) ) );
	|FormCompleteEdition show Editing;
	|FormCompleteDelivery show RoutePoint = Enum.InternalOrderPoints.Delivery and not Editing;
	|FormSendForApproval FormRework FormReject FormReturnToProcess FormCommitRejection FormCompleteApproval FormCompleteDelivery enable MyTask;
	|ItemsTable Services Date Currency Company Memo Department DeliveryDate Prices Currency Rate Factor Warehouse Responsible VATUse lock
	|not Editing
	|and ( not MyTask or inlist ( RoutePoint, Enum.InternalOrderPoints.Reject, Enum.InternalOrderPoints.Delivery ) );
	|ItemsSelectItems ServicesSelectItems ItemsScan ItemsReserve enable
	|( Editing
	|	or ( not inlist ( RoutePoint, Enum.InternalOrderPoints.Reject, Enum.InternalOrderPoints.Delivery ) and MyTask ) );
	|ProcessCompleted show RoutePoint = Enum.InternalOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Approve;
	|ProcessRejected show RoutePoint = Enum.InternalOrderPoints.Finish and Object.Resolution = Enum.Resolutions.Reject;
	|ShowPerformers enable RoutePoint <> Enum.InternalOrderPoints.Finish;
	|ChangesNotification show
	|Started
	|and RoutePoint <> Enum.InternalOrderPoints.Finish
	|and not MyTask;
	|Number lock Started;
	|PageChanges show inlist ( RoutePoint, Enum.InternalOrderPoints.Finish, Enum.InternalOrderPoints.Delivery ) and Object.Resolution = Enum.Resolutions.Approve;
	|MemoLabel show filled ( Object.Memo );
	|FormPurchaseOrder show inlist ( RoutePoint, Enum.InternalOrderPoints.Delivery ) and not Editing;
	|FormVendorInvoice show RoutePoint = Enum.InternalOrderPoints.Delivery and not Editing;
	|PicturesPanel show PicturesEnabled;
	|ItemsShowPictures press PicturesEnabled;
	|FormPrintInternalOrder show not Editing;
	|VAT ItemsVATCode ItemsVAT ServicesVATCode ServicesVAT show Object.VATUse > 0;
	|ItemsTotal ServicesTotal show Object.VATUse = 2;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setCurrentUser ()
	
	CurrentUser = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		return;
	endif; 
	if ( Object.Warehouse.IsEmpty () ) then
		settings = Logins.Settings ( "Company, Warehouse" );
		Object.Company = settings.Company;
		Object.Warehouse = settings.Warehouse;
	else
		Object.Company = DF.Pick ( Object.Warehouse, "Owner" );
	endif;
	Object.Department = Logins.Settings ( "Department" ).Department;
	Object.Currency = Application.Currency ();
	
EndProcedure 

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ServicesQuantity" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		Env.Q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( Object.Ref.IsEmpty () ) then
		return;
	endif; 
	selection = Env.Selection;
	meta = Metadata.Documents;
	ViewPurchaseOrders = AccessRight ( "View", meta.PurchaseOrder );
	if ( ViewPurchaseOrders ) then
		s = "
		|// #PurchaseOrders
		|select Items.Ref as Document, Items.Ref.Date as Date, Items.Ref.Number as Number
		|from Document.PurchaseOrder.Items as Items
		|where Items.DocumentOrder = &Ref
		|and not Items.Ref.DeletionMark
		|union
		|select Services.Ref as Document, Services.Ref.Date as Date, Services.Ref.Number as Number
		|from Document.PurchaseOrder.Services as Services
		|where Services.DocumentOrder = &Ref
		|and not Services.Ref.DeletionMark
		|order by Date
		|";
		selection.Add ( s );
	endif;
	ViewVendorInvoices = AccessRight ( "View", meta.VendorInvoice );
	if ( ViewVendorInvoices ) then
		s = "
		|// #VendorInvoices
		|select Documents.Ref as Document,
		|	case when Documents.ReferenceDate = datetime ( 1, 1, 1 ) then Documents.Date else Documents.ReferenceDate end as Date,
		|	case when Documents.Reference = """" then Documents.Number else Documents.Reference end as Number
		|from Document.VendorInvoice as Documents
		|where Documents.Ref in (
		|	select Items.Ref as Ref
		|	from Document.VendorInvoice.Items as Items
		|	where Items.DocumentOrder = &Ref
		|	union
		|	select Services.Ref
		|	from Document.VendorInvoice.Services as Services
		|	where Services.DocumentOrder = &Ref
		|)
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
	if ( ViewPurchaseOrders ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.PurchaseOrders, meta.PurchaseOrder ) );
	endif; 
	if ( ViewVendorInvoices ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorInvoices, meta.VendorInvoice ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	OrderForm.ActivateItem ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
	elsif ( EventName = Enum.RefreshItemPictures () ) then
		ItemPictures.Refresh ( ThisObject );
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Feature, Series" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		item = Fields.Item;
		row.Item = item;
		row.Series = Fields.Series;
		package = Fields.Package;
		row.Package = package;
		feature = Fields.Feature;
		row.Feature = feature;
		row.QuantityPkg = Fields.QuantityPkg;
		row.Capacity = Fields.Capacity;
		row.Quantity = Fields.Quantity;
		row.Price = Goods.Price ( , Object.Date, Object.Prices, item, package, feature, , , , Object.Warehouse, Object.Currency );
		data = DF.Values ( item, "VAT, VAT.Rate as Rate" );
		row.VATCode = data.VAT;
		row.VATRate = data.Rate;
		row.Reservation = PredefinedValue ( "Enum.Reservation.None" );
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
		row.QuantityPkg = row.QuantityPkg + Fields.QuantityPkg;
	endif; 
	Computations.Amount ( row );
	Computations.Total ( row, Object.VATUse );
	calcTotals ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure calcTotals ( Object )
	
	items = Object.Items;
	services = Object.Services;
	vat = items.Total ( "VAT" ) + services.Total ( "VAT" );
	amount = items.Total ( "Total" ) + services.Total ( "Total" );
	Object.VAT = vat;
	Object.Amount = amount;
	Object.GrossAmount = amount - ? ( Object.VATUse = 2, vat, 0 );
	
EndProcedure 

&AtClient
Procedure ChoiceProcessing ( SelectedValue, ChoiceSource )
	
	operation = SelectedValue.Operation;
	if ( operation = Enum.ChoiceOperationsPickItems () ) then
		addSelectedItems ( SelectedValue );
		addSelectedServices ( SelectedValue );
		calcTotals ( Object );
	elsif ( operation = Enum.ChoiceOperationsReserveItems () ) then
		reserveItem ( SelectedValue );
	endif; 
	
EndProcedure

&AtClient
Procedure addSelectedItems ( Params )
	
	itemsTable = Object.Items;
	for each selectedRow in Params.Items do
		row = itemsTable.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure addSelectedServices ( Params )
	
	services = Object.Services;
	for each selectedRow in Params.Services do
		row = services.Add ();
		FillPropertyValues ( row, selectedRow );
	enddo; 
	
EndProcedure

&AtClient
Procedure reserveItem ( Params )
	
	OrderForm.ReserveItem ( ThisObject, Params );
	calcTotals ( Object );
	
EndProcedure 

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	Forms.DeleteLastRow ( Object.Services, "Item" );
	calcTotals ( Object );
	if ( Editing ) then
		Cancel = true;
		startCommand ( PredefinedValue ( "Enum.Actions.CompleteEdition" ) );
	endif; 
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not OrderForm.CheckAccessibility ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	if ( not OrderForm.SetRowKeys ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageInternalOrderIsSaved (), Object.Ref );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure CurrencyOnChange ( Item )
	
	applyCurrency ();
	calcTotals ( Object );
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	data = CurrenciesSrv.Get ( Object.Currency, Object.Date );
	Object.Rate = data.Rate;
	Object.Factor = data.Factor;
	Appearance.Apply ( ThisObject, "Object.Currency" );
	
EndProcedure 

&AtClient
Procedure PricesOnChange ( Item )
	
	applyPrices ();
	
EndProcedure

&AtServer
Procedure applyPrices ()
	
	cache = new Map ();
	date = Object.Date;
	prices = Object.Prices;
	warehouse = Object.Warehouse;
	currency = Object.Currency;
	vatUse = Object.VATUse;
	for each row in Object.Items do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, row.Package, row.Feature, , , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	cache = new Map ();
	for each row in Object.Services do
		row.Prices = undefined;
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, , warehouse, currency );
		row.Price = Goods.Price ( cache, date, prices, row.Item, , row.Feature, , , , warehouse, currency );
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	
EndProcedure 

&AtClient
Procedure SendForApproval ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.SendToApproval" ) );
	
EndProcedure

&AtClient
Procedure startCommand ( Command )
	
	if ( Command = PredefinedValue ( "Enum.Actions.SendToApproval" )
		or Command = PredefinedValue ( "Enum.Actions.Return" ) ) then
		Output.SendForApprovalConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Rework" ) ) then
		Output.SendToReworkConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Approve" )
		or Command = PredefinedValue ( "Enum.Actions.CompleteApproval" ) ) then
		Output.ApproveConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Reject" ) ) then
		Output.RejectConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	else
		Output.CompleteRoutePoint ( ThisObject, Command, , "CommandConfirmation" );
	endif; 
	
EndProcedure

&AtClient
Procedure CommandConfirmation ( Answer, Command ) export
	
	if ( Answer <> DialogReturnCode.Yes ) then
		return;
	endif; 
	if ( Command = PredefinedValue ( "Enum.Actions.Approve" )
		or Command = PredefinedValue ( "Enum.Actions.CompleteApproval" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Approve" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Rework" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Rework" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.Reject" ) ) then
		Object.Resolution = PredefinedValue ( "Enum.Resolutions.Reject" );
		performCommand ( Command );
	elsif ( Command = PredefinedValue ( "Enum.Actions.CompleteEdition" ) ) then
		Editing = false;
		performCommand ( Command, false );
	else
		performCommand ( Command );
	endif;
	
EndProcedure

&AtClient
Procedure performCommand ( Command, CloseForm = true )
	
	Object.Action = Command;
	Object.Performer = CurrentUser;
	if ( Write () ) then
		if ( CloseForm ) then
			Close ();
		endif;
	endif; 
	
EndProcedure 

&AtClient
Procedure Approve ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Approve" ) );
	
EndProcedure

&AtClient
Procedure Rework ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Rework" ) );
	
EndProcedure

&AtClient
Procedure Reject ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Reject" ) );
	
EndProcedure

&AtClient
Procedure ReturnToProcess ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.Return" ) );
	
EndProcedure

&AtClient
Procedure CommitRejection ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CommitRejection" ) );
	
EndProcedure

&AtClient
Procedure CompleteApproval ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteApproval" ) );
	
EndProcedure

&AtClient
Procedure Modify ( Command )
	
	OrderForm.Modify ( ThisObject );
	
EndProcedure

&AtClient
Procedure CompleteEdition ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteEdition" ) );
	
EndProcedure

&AtClient
Procedure CompleteDelivery ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompleteDelivery" ) );
	
EndProcedure

&AtClient
Procedure ResolutionMemoChoiceProcessing ( Item, SelectedValue, StandardProcessing )
	
	StandardProcessing = false;
	if ( SelectedValue = "0" ) then
		addMemo ();
	elsif ( SelectedValue = "1" ) then
		showMemos ();
	endif; 
	
EndProcedure

&AtClient
Procedure addMemo ()
	
	p = new Structure ( "FillingValues", new Structure () );
	p.FillingValues.Insert ( "Document", Object.Ref );
	OpenForm ( "InformationRegister.InternalOrderResolutions.Form.NewMemo", p, ThisObject, , , , new NotifyDescription ( "ResolutionMemosNewMemo", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure showMemos ()
	
	p = new Structure ( "Filter", new Structure () );
	p.Filter.Insert ( "Document", Object.Ref );
	OpenForm ( "InformationRegister.InternalOrderResolutions.Form.List", p );
	
EndProcedure 

&AtClient
Procedure ResolutionMemoClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	
EndProcedure

&AtClient
Procedure ResolutionMemosNewMemo ( Result, Params ) export
	
	if ( Result = undefined ) then
		return;
	endif; 
	ResolutionMemo = Result;
	
EndProcedure 

&AtClient
Procedure ShowPerformers ( Command )
	
	OrderForm.OpenPerformers ( ThisObject );
	
EndProcedure

&AtClient
Procedure Chart ( Command )
	
	BPForm.ShowChart ( Object.Ref, Object.Process, ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure SelectItems ( Command )
	
	PickItems.Open ( ThisObject, pickParams () );
	
EndProcedure

&AtServer
Function pickParams ()
	
	return PickItems.GetParams ( ThisObject );
	
EndFunction 

&AtClient
Procedure Reserve ( Command )
	
	if ( ItemsRow = undefined ) then
		return;
	endif; 
	openReservation ();
	
EndProcedure

&AtClient
Procedure openReservation ()
	
	p = reservationParams ( Object.Items.IndexOf ( ItemsRow ) );
	OpenForm ( "DataProcessor.Items.Form.OrderItem", p, ThisObject );
	
EndProcedure 

&AtServer
Function reservationParams ( val RowIndex )
	
	return OrderForm.ReservationParams ( ThisObject, RowIndex );
	
EndFunction

&AtClient
Procedure Scan ( Command )
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ShowHidePictures ( Command )
	
	togglePictures ();
	
EndProcedure

&AtServer
Procedure togglePictures ()
	
	ItemPictures.Toggle ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ResizeOnChange ( Item )
	
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure PictureOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	ItemPictures.ClickProcessing ( EventData.Element.id, UUID );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	ShownProduct = ? ( ItemsRow = undefined, undefined, ItemsRow.Item );
	ItemPictures.Refresh ( ThisObject );
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	OrderRows.ResetReservation ( ItemsRow, PredefinedValue ( "Enum.Reservation.Invoice" ) );
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
	p.Insert ( "Warehouse", Object.Warehouse );
	p.Insert ( "Currency", Object.Currency );
	p.Insert ( "Item", ItemsRow.Item );
	p.Insert ( "Prices", Object.Prices );
	data = getItemData ( p );
	ItemsRow.Package = data.Package;
	ItemsRow.Capacity = data.Capacity;
	ItemsRow.Price = data.Price;
	ItemsRow.VATCode = data.VAT;
	ItemsRow.VATRate = data.Rate;
	Computations.Units ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getItemData ( val Params )
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate" );
	price = Goods.Price ( , Params.Date, Params.Prices, item, data.Package, , , , , Params.Warehouse, Params.Currency );
	data.Insert ( "Price", price );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif; 
	return data;
	
EndFunction 

&AtClient
Procedure ItemsFeatureOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure priceItem ()
	
	prices = ? ( ItemsRow.Prices.IsEmpty (), Object.Prices, ItemsRow.Prices );
	ItemsRow.Price = Goods.Price ( , Object.Date, prices, ItemsRow.Item, ItemsRow.Package, ItemsRow.Feature, , , , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ItemsPackageOnChange ( Item )
	
	applyPackage ();
	
EndProcedure

&AtClient
Procedure applyPackage ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
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
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure 

&AtServerNoContext
Function getPackageData ( val Params )
	
	package = Params.Package;
	capacity = DF.Pick ( package, "Capacity", 1 );
	price = Goods.Price ( , Params.Date, Params.Prices, Params.Item, package, Params.Feature, , , , Params.Warehouse, Params.Currency );
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
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPriceOnChange ( Item )

	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	Computations.Price ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsPricesOnChange ( Item )
	
	priceItem ();
	Computations.Amount ( ItemsRow );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsReservationOnChange ( Item )
	
	OrderRows.ResetStock ( ItemsRow );
	OrderRows.ResetOrder ( ItemsRow );
	
EndProcedure

// *****************************************
// *********** Table Services

&AtClient
Procedure ServicesOnActivateRow ( Item )
	
	ServicesRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ServicesOnEditEnd ( Item, NewRow, CancelEdit )
	
	calcTotals ( Object );
	OrderRows.ResetPerformer ( ServicesRow );
	
EndProcedure

&AtClient
Procedure ServicesAfterDeleteRow ( Item )
	
	calcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ServicesItemOnChange ( Item )
	
	applyService ();
	
EndProcedure

&AtClient
Procedure applyService ()
	
	p = new Structure ();
	p.Insert ( "Date", Object.Date );
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
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , , , , Params.Warehouse, Params.Currency );
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
	ServicesRow.Price = Goods.Price ( , Object.Date, prices, ServicesRow.Item, , ServicesRow.Feature, , , , Object.Warehouse, Object.Currency );
	
EndProcedure 

&AtClient
Procedure ServicesQuantityOnChange ( Item )
	
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPriceOnChange ( Item )

	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );

EndProcedure

&AtClient
Procedure ServicesAmountOnChange ( Item )
	
	Computations.Price ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPricesOnChange ( Item )
	
	priceService ();
	Computations.Amount ( ServicesRow );
	Computations.Total ( ServicesRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ServicesPerformerOnChange ( Item )
	
	OrderRows.ResetDepartment ( ServicesRow );
	
EndProcedure

&AtClient
Procedure VATUseOnChange ( Item )
	
	applyVATUse ();
	
EndProcedure

&AtClient
Procedure applyVATUse ()
	
	vatUse = Object.VATUse;
	for each row in Object.Items do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	for each row in Object.Services do
		Computations.Amount ( row );
		Computations.Total ( row, vatUse );
	enddo; 
	calcTotals ( Object );
	Appearance.Apply ( ThisObject, "Object.VATUse" );
	
EndProcedure

&AtClient
Procedure ItemsVATCodeOnChange ( Item )
	
	ItemsRow.VATRate = DF.Pick ( ItemsRow.VATCode, "Rate" );
	Computations.Total ( ItemsRow, Object.VATUse );
	
EndProcedure

&AtClient
Procedure ItemsVATOnChange ( Item )
	
	Computations.Total ( ItemsRow, Object.VATUse, false );
	
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