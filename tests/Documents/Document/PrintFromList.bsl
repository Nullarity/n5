// Description:
// Opens print form from the List of documents and prints the first document
//
// Conditions:
// List of documents should have document with the subject: "5 files"
// (they actually should be inside)

Call ( "Common.Init" );

file = "5 files";
list = Run ( "Filter", new Structure ( "Subject", file ) );

Click ( "#PrintAttachment" );
With ( "Select files" );
Click ( "#FilesUnmarkAll" );
Click ( "OK" );

With ( DialogsTitle );
Click ( "OK" );

With ( "Documents" );
Click ( "#PrintAttachment" );
With ( "Select files" );
Click ( "#FilesUnmarkAll" );
table = Activate ( "#Files" );
table.GotoFirstRow ();
Click ( "#FilesUse", table );
Click ( "OK" );