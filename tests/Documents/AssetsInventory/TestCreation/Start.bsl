Call ( "Common.Init" );
CloseAll ();

env = Run ( "Create", Call ( "Common.GetID" ) + "#" );
Run ( "ReceiveItemsBaseOn", env );
