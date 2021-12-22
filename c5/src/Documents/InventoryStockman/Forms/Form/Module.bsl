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
	
	isApplied ();
	Appearance.Apply ( ThisObject );
	ReadOnly = InventoryApplied;
	
EndProcedure

&AtServer
Procedure isApplied ()
	
	s = "select top 1 1 from Document.Инвентаризация.Inventories where Inventory = &Ref and Ref.Posted";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	InventoryApplied = not q.Execute ().IsEmpty ();
	
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
	|// #Inventories
	|select Documents.Ref as Document, Documents.Ref.Date as Date, Documents.Ref.Number as Number
	|from Document.Инвентаризация.Inventories as Documents
	|where Documents.Inventory = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

&AtServer
Procedure setURLPanel ()
	
	parts = new Array ();
	meta = Metadata.Documents;
	if ( not isNew () ) then
		parts.Add ( URLPanel.DocumentsToURL ( Env.Inventories, meta.Инвентаризация ) );
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
	|Warning show InventoryApplied;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	if ( Object.Ref.IsEmpty () ) then
		AttachIdleHandler ( "openScanner", 0.01, true );
	endif;
	
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
	elsif ( EventName = Enum.MessageAccountingInventoryIsSaved () ) then
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
		item = Fields.Item;
		row.Item = item;
		row.Package = Fields.Package;
		row.Lot = Fields.Lot;
		row.Quantity = Fields.Quantity;
		row.Print = 1;
		row.Balance = getBalance ( item, Object.Warehouse );
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

&AtServerNoContext
Function getBalance ( val Item, val Warehouse )
	
	s = "
	|select Balances.КоличествоBalance as Balance
	|from AccountingRegister.Хозрасчетный.Balance ( , Account.Code = ""217.1"", ,
	|	ExtDimension1 = &Item and ExtDimension2 = &Warehouse ) as Balances
	|";
	q = new Query ( s );
	q.SetParameter ( "Item", Item );
	q.SetParameter ( "Warehouse", Warehouse );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Balance );
	
EndFunction

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
	
	item = ItemsRow.Item;
	ItemsRow.Package = DF.Pick ( ItemsRow.Item, "ЕдИзм" );
	ItemsRow.Balance = getBalance ( item, Object.Warehouse );
	
EndProcedure 

&AtClient
Procedure ItemsLotStartChoice ( Item, ChoiceData, StandardProcessing )
	
	LotForm.ShowList ( Item, itemsRow.Item, StandardProcessing );
	                   
EndProcedure
