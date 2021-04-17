Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.Invoice" );
With ( "Invoice (create)" );

Choose ( "More / #Department" );

With ( "Departments" );
CheckState ( "#CompanyFilter", "Visible", false );