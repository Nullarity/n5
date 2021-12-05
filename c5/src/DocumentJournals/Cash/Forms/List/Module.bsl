&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	fillAllowedDocuments ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure init ()
	
	CurrencyFilter = Application.Currency ();

EndProcedure

&AtServer
Procedure readAppearance ()
	
	rules = new Array ();
	rules.Add ( "
	|Currency show empty ( CurrencyFilter );
	|" );
	Appearance.Read ( ThisObject, rules );
	
EndProcedure

&AtServer
Procedure fillAllowedDocuments ()
	
	types = Metadata.DefinedTypes;
	addDocuments ( types.CashReceiptBase.Type.Types () );
	addDocuments ( types.CashVoucherBase.Type.Types () );
	addOperations ();
	
EndProcedure 

&AtServer
Procedure addOperations ()
	
	if ( not AccessRight ( "Insert", Metadata.Documents.Entry ) ) then
		return;
	endif; 
	for each operation in getOperations () do
		AllowedDocuments.Add ( operation.Ref, operation.Description );
	enddo; 

EndProcedure 

&AtServer
Function getOperations ()
	
	s = "
	|select top 15 Operations.Ref as Ref, Operations.Description as Description
	|from Catalog.Operations as Operations
	|where not Operations.DeletionMark
	|and Operations.Operation in ( value ( Enum.Operations.CashExpense ), value ( Enum.Operations.CashReceipt ) )
	|order by Operations.Description
	|";
	q = new Query ( s );
	return q.Execute ().Unload ();
	
EndFunction 

&AtServer
Procedure addDocuments ( Types )
	
	entry = Type ( "DocumentRef.Entry" );
	for each type in Types do
		if ( type = entry ) then
			continue;
		endif; 
		meta = Metadata.FindByType ( type );
		if ( AccessRight ( "Insert", meta ) ) then
			AllowedDocuments.Add ( meta.Name, meta.Presentation () );
		endif; 
	enddo; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CreateDocument ( Command )
	
	showMenu ( Items.FormCommandBar );
	
EndProcedure

&AtClient
Procedure showMenu ( Control )

	if ( AllowedDocuments.Count () = 0 ) then
		Output.ListIsReadonly ();
	else
		ShowChooseFromMenu ( new NotifyDescription ( "MenuSelected", ThisObject ), AllowedDocuments, Control );
	endif; 
	
EndProcedure 

&AtClient
Procedure MenuSelected ( Item, Params ) export
	
	if ( Item = undefined ) then
		return;
	endif; 
	openDocument ( Item.Value );
	
EndProcedure 

&AtClient
Procedure openDocument ( Target, Ref = undefined, Copying = false, Callback = undefined )
	
	p = new Structure ();
	if ( Ref <> undefined ) then
		if ( Copying ) then
			p.Insert ( "CopyingValue", Ref );
		else
			p.Insert ( "Key", Ref );
		endif; 
	endif; 
	if ( TypeOf ( Target ) = Type ( "CatalogRef.Operations" ) ) then
		name = "Entry";
		p.Insert ( "FillingValues", new Structure ( "Operation", Target ) );
	else
		name = Target;
	endif; 
	OpenForm ( "Document." + name + ".ObjectForm", p, Items.List, , , , CallBack );
	
EndProcedure 

&AtClient
Procedure ShowRecords ( Command )
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	openRecords ();
	
EndProcedure

&AtClient
Procedure openRecords ()
	
	p = new Structure ( "Document", DF.Pick ( TableRow.Ref, "Base" ) );
	OpenForm ( "Report.Records.Form", p );
	
EndProcedure 

&AtClient
Procedure CurrencyFilterOnChange ( Item )
	
	applyCurrency ();
	
EndProcedure

&AtServer
Procedure applyCurrency ()
	
	Appearance.Apply ( ThisObject, "CurrencyFilter" );
	filterByCurrency ();
	
EndProcedure

&AtServer
Procedure filterByCurrency ()
	
	DC.ChangeFilter ( List, "Currency", CurrencyFilter, not CurrencyFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure LocationFilterOnChange ( Item )
	
	filterByLocation ();
	
EndProcedure

&AtServer
Procedure filterByLocation ()
	
	DC.ChangeFilter ( List, "Location", LocationFilter, not LocationFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListNewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	activateDocument ( NewObject );
	
EndProcedure

&AtClient
Procedure activateDocument ( Document )
	
	type = TypeOf ( Document );
	if ( type = Type ( "DocumentRef.CashReceipt" )
		or type = Type ( "DocumentRef.CashVoucher" ) ) then
		ref = Document;
	else
		//@skip-warning
		ref = PettyCashSrv.Search ( Document );
		if ( ref.IsEmpty () ) then
			return;
		endif; 
	endif; 
	NotifyChanged ( ref );
	Items.List.CurrentRow = ref;
	
EndProcedure 

&AtClient
Procedure ListOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	StandardProcessing = false;
	openBase ();
	
EndProcedure

&AtClient
Procedure openBase ()
	
	if ( TableRow = undefined ) then
		return;
	endif; 
	ref = TableRow.Ref;
	base = baseParams ( ref );
	callback = new NotifyDescription ( "DocumentClosed", ThisObject, ref );
	openDocument ( base.Name, base.Ref, , callback );
	
EndProcedure 

&AtServerNoContext
Function baseParams ( val Ref )
	
	data = DF.Values ( Ref, "Disconnected, Base" );
	base = ? ( data.Disconnected, Ref, data.Base );
	name = Metadata.FindByType ( TypeOf ( base ) ).Name;
	result = new Structure ( "Name, Ref", name, base );
	return result;
	
EndFunction 

&AtClient
Procedure DocumentClosed ( Result, Reference ) export
	
	NotifyChanged ( Reference );
	
EndProcedure 

&AtClient
Procedure ListBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	if ( Clone ) then
		base = baseParams ( TableRow.Ref );
		openDocument ( base.Name, base.Ref, true );
	else
		showMenu ( Item );
	endif; 
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange ( Item, Cancel )
	
	Cancel = true;
	openBase ();

EndProcedure
