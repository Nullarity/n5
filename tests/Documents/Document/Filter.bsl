// Description:
// Opens list of documents and filters that list by Parameter value
//
// Parameters:
// Subject: filter by document subject
//
// Returns:
// Table of documents

Call ( "Common.Init" );

CloseAll ();
MainWindow.ExecuteCommand ( "e1cib/list/Document.Document" );

form = With ( "Documents" );
list = Activate ( "#DocumentsList" );
subject = _.Subject;

p = Call ( "Common.Find.Params" );
p.Where = "Subject";
p.What = subject;
p.Button = "#DocumentsListContextMenuFind";
Call ( "Common.Find", p );

With ( form );

return list;