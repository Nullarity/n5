Call ( "Common.Init" );
CloseAll ();

Run ( "Create", Call ( "Common.GetID" ) );
Run ( "Logic" );
With ( "Assets Write Off*" );
Run ( "PrintWriteOff" );	


