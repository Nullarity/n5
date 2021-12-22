&AtServer
var Env;
&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	update ();
	
EndProcedure

&AtServer
Procedure update ()
	
	Appearance.Apply ( ThisObject );
	ReadOnly = Object.Invoiced;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( isNew () ) then
		DocumentForm.SetCreator ( Object );
		initNew ();
	endif; 
	setLinks ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Function isNew ()
	
	return Object.Ref.IsEmpty ();
	
EndFunction

&AtServer
Procedure initNew ()
	
	if ( Object.Warehouse.IsEmpty () ) then
		data = DF.Values ( Object.Creator, "ОсновнаяФирма, ОсновнойСклад" );
		Object.Company = data.ОсновнаяФирма;
		Object.Warehouse = data.ОсновнойСклад;
	else
		Object.Company = DF.Pick ( Object.Creator, "ОсновнаяФирма" );
	endif;
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	SQL.Init ( Env );
	sqlLinks ();
	if ( Env.Selection.Count () = 0 ) then
		ShowLinks = false;
	else
		q = Env.Q;
		q.SetParameter ( "Ref", Object.Ref );
		SQL.Perform ( Env, false );
		setURLPanel ();
	endif;
	Appearance.Apply ( ThisObject, "ShowLinks" );

EndProcedure 

&AtServer
Procedure sqlLinks ()
	
	if ( isNew () ) then
		return;
	endif; 
	s = "
	|// #VendorInvoices
	|select Documents.Ref as Document, Documents.Date as Date, Documents.Number as Number
	|from Document.ПоступлениеТМЦ as Documents
	|where Documents.Receipt = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.VendorInvoices, meta.ПоступлениеТМЦ ) );
	endif; 
	s = URLPanel.Build ( parts );
	if ( s = undefined ) then
		ShowLinks = false;
	else
		ShowLinks = true;
		Links = s;
	endif; 
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Links show ShowLinks;
	|Warning show Object.Invoiced;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	Forms.DeleteLastRow ( Object.Items, "Item" );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and TypeOf ( Source.FormOwner ) = Type ( "ClientApplicationForm" )
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		addItem ( Parameter );
		Modified = true;
	elsif ( EventName = Enum.MessageVendorInvoiceIsSaved ()
		and Parameter.Receipt = Object.Ref ) then
		reread ();
	endif; 
	
EndProcedure

&AtServer
Procedure addItem ( Fields )
	
	search = new Structure ( "Item, Package, Lot" );
	FillPropertyValues ( search, Fields );
	rows = Object.Items.FindRows ( search );
	if ( rows.Count () = 0 ) then
		row = Object.Items.Add ();
		row.Item = Fields.Item;
		row.Package = Fields.Package;
		row.Lot = Fields.Lot;
		row.Quantity = Fields.Quantity;
		row.Print = 1;
	else
		row = rows [ 0 ];
		row.Quantity = row.Quantity + Fields.Quantity;
	endif; 
	if ( not Fields.BarcodeFound
		and not row.Lot.IsEmpty () ) then
		row.Print = 1;
	else
		row.Print = 0;
	endif;
	
EndProcedure 

&AtServer
Procedure reread ()
	
	obj = Object.Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	setLinks ();
	update ();
	
EndProcedure

// *****************************************
// *********** Form events

&AtClient
Procedure LinksURLProcessing ( Item, FormattedStringURL, StandardProcessing )
	
	URLPanel.OpenLink ( FormattedStringURL, StandardProcessing );
	
EndProcedure                                                                

// *****************************************
// *********** Table Items

&AtClient
Procedure Scan ( Command )
	
	openScanner ();
	
EndProcedure

&AtClient
Procedure openScanner ()
	
	ScanForm.Open ( ThisObject, true );
	
EndProcedure

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsItemOnChange ( Item )
	
	applyItem ();
	
EndProcedure

&AtClient
Procedure applyItem ()
	
	ItemsRow.Package = DF.Pick ( ItemsRow.Item, "ЕдИзм" );
	
EndProcedure 

&AtClient
Procedure ItemsLotStartChoice ( Item, ChoiceData, StandardProcessing )
	
	LotForm.ShowList ( Item, itemsRow.Item, StandardProcessing );
	                   
EndProcedure

&AtClient
Procedure ItemsOnStartEdit ( Item, NewRow, Clone )
	
	if ( NewRow
		and not Clone ) then
		initRow ();
	endif;
	
EndProcedure

&AtClient
Procedure initRow ()
	
	Items.Items.CurrentData.Print = 1;
	
EndProcedure
