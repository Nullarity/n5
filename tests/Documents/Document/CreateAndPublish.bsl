// Description:
// Creates & publishes a new Document
//
// Returns:
// Subject

Call ( "Common.Init" );

MainWindow.ExecuteCommand ( "e1cib/data/Document.Document" );

form = With ( "Document (create)" );
subject = ? ( _ = undefined, "_Document: " + CurrentDate (), _ );

Set ( "Subject", subject );

Click ( "#FormWrite" );
actualSubject = Fetch ( "#Subject" );

Click ( "#FormPublish" );

With ( DialogsTitle );
Click ( "Yes" );

With ( DialogsTitle );
Click ( "Yes" );

return actualSubject;
