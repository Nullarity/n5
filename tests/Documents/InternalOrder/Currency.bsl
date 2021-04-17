Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.InternalOrder" );
form = With ( "Internal Order (create)" );

Activate ( "More" );
Check ( "#Currency", __.LocalCurrency );
CheckState ( "#Rate", "Enable", false );
CheckState ( "#Factor", "Enable", false );

Set ( "#Currency", "CAD" );
form.GotoNextItem ();
CheckState ( "#Rate", "Enable" );
CheckState ( "#Factor", "Enable" );
