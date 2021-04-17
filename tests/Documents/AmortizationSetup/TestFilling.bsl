Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.AmortizationSetup" );
With ( "Amortization Setup (create)" );
Click ( "#ItemsFill" );
With ( "Fill*" );
Click ( "Fill" );
