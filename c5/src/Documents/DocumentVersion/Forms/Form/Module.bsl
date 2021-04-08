&AtClient
var AttachmentRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	loadTable ();
	Attachments.Read ( Object.Ref, Tables.Attachments );
	initPreview ();
	setAttachmentsCount ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure loadTable ()
	
	currentObject = FormAttributeToValue ( "Object" );
	TabDoc = currentObject.Table.Get ();
	
EndProcedure

&AtServer
Procedure initPreview ()
	
	if ( Object.IsEmpty ) then
		if ( Tables.Attachments.Count () > 0 ) then
			row = Tables.Attachments [ 0 ];
			loadHTML ( row.File, row.ID );
		endif; 
	else
		loadDocument ();
	endif; 
	
EndProcedure 

&AtServer
Procedure loadHTML ( val File, val ID )
	
	Preview = getHTML ( File, ID );
	PreviewMode = 2;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

&AtServer
Function getHTML ( val File, val ID )
	
	folderURL = CKEditorSrv.GetFolderURL ( Object.FolderID ) + "/";
	index = CKEditorSrv.GetFolder ( Object.FolderID ) + "\" + ID + "\index.html";
	if ( FileSystem.Exists ( index ) ) then
		return folderURL + ID + "/index.html";
	else
		url = folderURL + EncodeString ( File, StringEncodingMethod.URLEncoding );
		return AttachmentsSrv.PreviewScript ( File, url );
	endif; 
	
EndFunction 

&AtServer
Procedure loadDocument ()
	
	Preview = CKEditorSrv.GetHTML ( Object.FolderID, true );
	DocumentPresenter.Compile ( Preview, Object.CurrentVersion );
	PreviewMode = 1;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

&AtServer
Procedure setAttachmentsCount ()
	
	AttachmentsCount = Tables.Attachments.Count ();

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ShowDocument AttachmentsContextMenuShowDocument show
	|not Object.IsEmpty
	|and AttachmentsCount > 0
	|and PreviewMode <> 1;
	|ShowHTMLToottip show
	|not Object.IsEmpty
	|and AttachmentsCount > 0
	|and PreviewMode = 1;
	|ShowHTML AttachmentsContextMenuShowHTML show AttachmentsCount > 0 and PreviewMode = 3;
	|ShowPDF AttachmentsContextMenuShowPDF Open show AttachmentsCount > 0 and PreviewMode = 2;
	|OpenFile show AttachmentsCount > 0 and PreviewMode > 1
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure PreviewOnClick ( Item, EventData, StandardProcessing )
	
	StandardProcessing = false;
	Emails.ProcessLink ( EventData, StandardProcessing );
	
EndProcedure

// *****************************************
// *********** Group Preview

&AtClient
Procedure ShowDocument ( Command )
	
	loadDocument ();

EndProcedure

&AtClient
Procedure ShowPDF ( Command )
	
	if ( AttachmentRow = undefined ) then
		return;
	endif; 
	loadPDF ( AttachmentRow.File, AttachmentRow.ID );
	
EndProcedure

&AtServer
Procedure loadPDF ( val File, val ID )
	
	Preview = getPDF ( File, ID );
	PreviewMode = 3;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

&AtServer
Function getPDF ( val File, val ID )
	
	folderURL = CKEditorSrv.GetFolderURL ( Object.FolderID ) + "/";
	if ( FileSystem.GetExtension ( File ) = "pdf" ) then
		return folderURL + "/" + File;
	else
		pdf = CKEditorSrv.GetFolder ( Object.FolderID ) + "\" + ID + "\" + ID + ".pdf";
		if ( FileSystem.Exists ( pdf ) ) then
			return folderURL + ID + "/" + ID + ".pdf";
		endif; 
	endif;
	return AttachmentsSrv.PreviewNotSupported ();

EndFunction 

&AtClient
Procedure ShowHTML ( Command )
	
	if ( AttachmentRow = undefined ) then
		return;
	endif; 
	loadHTML ( AttachmentRow.File, AttachmentRow.ID );
	
EndProcedure

&AtClient
Procedure OpenFile ( Command )
	
	openSelectedFile ();
	
EndProcedure

&AtClient
Procedure openSelectedFile ()
	
	Items.Attachments.CurrentRow = SelectedFile;
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsRun () ) );
	
EndProcedure 

&AtClient
Function attachmentParams ( Command )
	
	p = Attachments.GetParams ();
	p.Command = Command;
	p.Control = Items.Attachments;
	p.Table = Tables.Attachments;
	p.FolderID = Object.FolderID;
	p.Ref = Object.Ref;
	return p;
	
EndFunction 

&AtClient
Procedure OpenAttachment ( Command )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsRun () ) );
	
EndProcedure

// *****************************************
// *********** Table Attachments

&AtClient
Procedure AttachmentsOnActivateRow ( Item )
	
	AttachmentRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure AttachmentsSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	SelectedFile = SelectedRow;
	loadHTML ( AttachmentRow.File, AttachmentRow.ID );
	
EndProcedure

&AtClient
Procedure DownloadFile ( Command )

	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownload () ) );

EndProcedure

&AtClient
Procedure DownloadAllFiles ( Command )
	
	Attachments.Command ( attachmentParams ( Enum.AttachmentsCommandsDownloadAll () ) );
	
EndProcedure
