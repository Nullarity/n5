// Description:
// Publish Document with chaged files
//
// Conditions:
// List of documents should have document with the subject: "5 files"
// (they actually should be inside)

Call ( "Common.Init" );

date = CurrentDate ();
file = "5 files";
newName = "Order.docx";
list = Run ( "Filter", new Structure ( "Subject", file ) );

Click ( "#Copy1" );

form = With ( "Document (create)" );

Activate ( "#Attachments" );
Click ( "#AttachmentsContextMenuRenameFile" );
With ( "Please enter*" );
Click ( "OK" );
if ( not Waiting ( DialogsTitle ) ) then
	Message ( "Warning message should be shown" );
	Stop ();
endif;
With ( DialogsTitle );
Click ( "OK" );

With ( form );
Click ( "#AttachmentsContextMenuRenameFile" );
With ( "Please enter*" );
Set ( "#InputFld", newName );
Click ( "OK" );

With ( form );
table = Activate ( "#Attachments" );
name = Fetch ( "#AttachmentsFile", table );
if ( Find ( name, newName ) = 0 ) then
	Message ( "Something wrong with file renaming. New file should be: " + newName );
	Stop ();
endif;
