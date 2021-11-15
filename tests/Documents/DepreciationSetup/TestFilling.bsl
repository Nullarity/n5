Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.DepreciationSetup" );
With ( "Depreciation Setup (create)" );
Click ( "#ItemsFill" );
With ( "Fill*" );
Click ( "Fill" );
