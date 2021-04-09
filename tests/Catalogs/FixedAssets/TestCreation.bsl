Connect ();
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.FixedAssets" );
With ( "Fixed Assets (cr*" );

Set ( "#Description", "_Test cteation: " + CurrentDate () );
Click ( "#FormWrite" );
