&AtClient
var ItemsRow;
&AtClient
var ShipmentsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readStatus ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readStatus ()
	
	Status = InformationRegisters.PickupOrderStatuses.Get ( new Structure ( "Document", Object.Ref ) ).Status;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Output.InteractiveCreationRestricted ();
		Cancel = true;
		return;
	endif; 
	setAccuracy ();
	Options.Company ( ThisObject, Object.Company );
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|FormStart show Status = Enum.ShipmentPoints.New;
	|FormComplete show Status = Enum.ShipmentPoints.Picking;
	|FormWrite show Status <> Enum.ShipmentPoints.Finish;
	|ProcessCompleted show Status = Enum.ShipmentPoints.Finish;
	|MemoLabel show filled ( Object.Memo );
	|Items lock Status <> Enum.ShipmentPoints.Picking;
	|Memo lock Status = Enum.ShipmentPoints.Finish
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure
	
&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg, ShipmentsQuantity, ShipmentsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsQuantityBack, ItemsQuantityPkgBack, ShipmentsQuantityBack, ShipmentsQuantityPkgBack", , false );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantity, ItemsTotalQuantityPkg", false );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	readStatus ();
	Appearance.Apply ( ThisObject, "Status" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	NotifyChanged ( Type ( "DocumentRef.Shipment" ) );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		setItem ( Parameter );
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
	calcQuantityBack ();
	applyQuantity ();
	
EndProcedure 

&AtClient
Procedure calcQuantityBack ()
	
	ItemsRow.QuantityBack = ItemsRow.QuantityPlan - ItemsRow.Quantity;
	ItemsRow.QuantityPkgBack = ItemsRow.QuantityBack / ItemsRow.Capacity;
	
EndProcedure 

&AtClient
Procedure applyQuantity ()
	
	search = new Structure ( "Item, Feature, Package" );
	for each row in Object.Items do
		quantity = row.Quantity;
		quantityPkg = row.QuantityPkg;
		FillPropertyValues ( search, row );
		rows = Object.Shipments.FindRows ( search );
		for each shipmentRow in rows do
			shipmentRow.Quantity = Min ( quantity, shipmentRow.QuantityPlan );
			shipmentRow.QuantityPkg = Min ( quantityPkg, shipmentRow.QuantityPkgPlan );
			shipmentRow.QuantityBack = shipmentRow.QuantityPlan - shipmentRow.Quantity;
			shipmentRow.QuantityPkgBack = shipmentRow.QuantityPkgPlan - shipmentRow.QuantityPkg;
			quantity = quantity - shipmentRow.Quantity;
			quantityPkg = quantityPkg - shipmentRow.QuantityPkg;
		enddo; 
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure StartPicking ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.StartPicking" ) );
	
EndProcedure

&AtClient
Procedure startCommand ( Command )
	
	if ( Command = PredefinedValue ( "Enum.Actions.StartPicking" ) ) then
		Output.StartShippingConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	elsif ( Command = PredefinedValue ( "Enum.Actions.CompletePicking" ) ) then
		Output.CompleteShipmentConfirmation ( ThisObject, Command, , "CommandConfirmation" );
	endif; 
	
EndProcedure

&AtClient
Procedure CommandConfirmation ( Answer, Command ) export
	
	if ( Answer <> DialogReturnCode.Yes ) then
		return;
	endif; 
	if ( Command = PredefinedValue ( "Enum.Actions.StartPicking" ) ) then
		performCommand ( Command, false );
	elsif ( Command = PredefinedValue ( "Enum.Actions.CompletePicking" ) ) then
		performCommand ( Command, true );
	endif;
	
EndProcedure

&AtClient
Procedure performCommand ( Command, CloseForm )
	
	Object.Action = Command;
	if ( Write () ) then
		if ( CloseForm ) then
			Close ();
		endif;
	else
		Output.OperationNotPerformed ();
	endif; 
	
EndProcedure 

&AtClient
Procedure Complete ( Command )
	
	startCommand ( PredefinedValue ( "Enum.Actions.CompletePicking" ) );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", new Structure ( "JustScan", true ), ThisObject );
	
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
Procedure ItemsQuantityPkgOnChange ( Item )
	
	Computations.Units ( ItemsRow );
	calcQuantityBack ();
	applyQuantity ();
	
EndProcedure

&AtClient
Procedure ItemsQuantityOnChange ( Item )
	
	Computations.Packages ( ItemsRow );
	calcQuantityBack ();
	applyQuantity ();

EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ShipmentsOnActivateRow ( Item )
	
	ShipmentsRow = Items.Shipments.CurrentData;
	
EndProcedure

&AtClient
Procedure ShipmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	ShowValue ( , ShipmentsRow.Shipment );
	
EndProcedure
