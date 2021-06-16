Call ( "Common.Init" );
CloseAll ();

Call ( "Catalogs.UserSettings.CostOnline", true );

Run ( "Create", "A046" );
With ();
Click ( "#FormDocumentWriteOffCreateBasedOn" );
Run ( "WriteOffBaseOn" );
With ( "Inventory*" );
Click ( "#FormDocumentReceiveItemsCreateBasedOn" );
Run ( "ReceiveItemsBaseOn" );

With ( "Inventory*", true );
Run ( "PrintForm" );
