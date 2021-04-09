// Description:
// Publish Document with chaged files
//
// Conditions:
// List of documents should have document with the subject: "2 Word documents"
// (they actually should be inside)

Call ( "Common.Init" );

file = "2 Word files";
list = Run ( "Filter", new Structure ( "Subject", file ) );

list.ChangeRow ();

form = With ( file );
editor = Get ( "TextEditor" );
editMode = editor.CurrentVisible ();

if ( editMode ) then
	raise ( "Document " + file + " should be published" );
endif;

Click ( "#FormEdit" );
With ( DialogsTitle );
Click ( "Yes" );
With ( form );
Activate ( "Attachments" );
Click ( "#AttachmentsOpenAttachment" );
DoMessageBox ( "
|Please perform these steps:
|1. Change something in the opened file
|2. Save & close that file
|3. Click OK
|" );
Click ( "Publish" );
With ( DialogsTitle );
Click ( "Yes" );
With ( "Would you like*" );
Click ( "Uncheck all" );
Click ( "Mark all" );
Click ( "Upload" );

With ( "Publishing" );
Set ( "Comment", CurrentDate () );
Click ( "Publish" );
