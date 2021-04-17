Call ( "Common.Init" );
CloseAll ();

Call ( "Catalogs.UserSettings.CostOnline", true );

Run ( "Create", "2849658A#" );
With ();
Click ( "#FormDocumentWriteOffCreateBasedOn" );
Run ( "WriteOffBaseOn" );
With ( "Inventory*" );
Click ( "#FormDocumentReceiveItemsCreateBasedOn" );
Run ( "ReceiveItemsBaseOn" );

With ( "Inventory*" );
Run ( "PrintForm" );
