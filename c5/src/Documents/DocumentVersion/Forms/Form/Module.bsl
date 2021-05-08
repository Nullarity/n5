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
	
	Preview = getHTML ( File );
	PreviewMode = 2;
	Appearance.Apply ( ThisObject, "PreviewMode" );
	
EndProcedure 

&AtServer
Function getHTML ( File )
	
	address = AttachmentsSrv.GetFile ( Object.FolderID, File, undefined, UUID );
	return AttachmentsSrv.PreviewScript ( File, address );
	
EndFunction 

&AtServer
Procedure loadDocument ()
	
	ref = Object.CurrentVersion;
	Preview = DF.Pick ( ref, "Data" ).Get ();
	DocumentPresenter.Compile ( Preview, ref );
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
	p.Form = ThisObject;
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
