
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setRemote ();
	PettyCash.Read ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure setRemote ()
	
	Remote = DF.Pick ( Object.Location, "Remote" );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Output.RetailSalesInteractiveCreationError ();
		Cancel = true;
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
	|Warning UndoPosting show Object.Posted;
	|Warning1 hide Object.Posted;
	|Items Number Memo CashFlow Account lock Object.Posted;
	|VAT ItemsVATCode ItemsVAT show Object.VATUse > 0;
	|ItemsTotal show Object.VATUse = 2;
	|NewReceipt show empty ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash and not Remote;
	|Receipt FormReceipt show filled ( Receipt ) and Object.Method = Enum.PaymentMethods.Cash and not Remote;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setAccuracy ()
	
	Options.SetAccuracy ( ThisObject, "ItemsQuantity, ItemsQuantityPkg" );
	Options.SetAccuracy ( ThisObject, "ItemsTotalQuantityPkg, ItemsTotalQuantity", false );
	
EndProcedure 

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	PettyCash.Read ( ThisObject );
	Appearance.Apply ( ThisObject, "Object.Posted" );	
	
EndProcedure

&AtClient
Procedure NewReceipt ( Command )
	
	notifyNew = Object.Ref.IsEmpty ();
	createReceipt ();
	PettyCash.Open ( ThisObject, notifyNew );
	
EndProcedure

&AtServer
Procedure createReceipt ()
	
	PettyCash.NewReference ( ThisObject );
	Appearance.Apply ( ThisObject, "Receipt" );
	
EndProcedure 

&AtClient
Procedure ReceiptClick ( Item, StandardProcessing )
	
	PettyCash.ClickProcessing ( ThisObject, StandardProcessing );

EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure ItemsTableSelection ( Item, RowSelected, Field, StandardProcessing )
	
	if ( Item.CurrentItem = Items.ItemsTableBase ) then
		StandardProcessing = false;
		openBase ();
	endif;
	
EndProcedure

&AtClient
Procedure openBase ()
	
	base = Items.ItemsTable.CurrentData.Base;
	if ( base <> undefined ) then
		ShowValue ( , base );
	endif;

EndProcedure