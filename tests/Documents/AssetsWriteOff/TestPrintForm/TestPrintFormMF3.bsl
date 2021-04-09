Call ( "Common.Init" );
CloseAll ();
Call ( "Documents.AssetsWriteOff.TestCreation.Create", "2A6C38CC" );
With ( "Assets Write Off*" );
Run ( "PrintMF3" );