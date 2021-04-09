// Description:
// Opens print form from the Form of documents
//
// Conditions:
// List of documents should have document with the subject: "5 files"
// (they actually should be inside)

Call ( "Common.Init" );

file = "5 files";
list = Run ( "Filter", new Structure ( "Subject", file ) );
list.ChangeRow ();

With ( file );
Click ( "#AttachmentsPrintAttachment" );
