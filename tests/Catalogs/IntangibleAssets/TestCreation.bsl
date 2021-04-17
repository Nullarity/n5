Connect ();
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.IntangibleAssets" );
With ( "Intangible Assets (cr*" );

Set ( "#Description", "_Test cteation: " + CurrentDate () );
Click ( "#FormWrite" );
