// Create document from list

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/list/Document.Sale");
Check("#WarehouseFilter", "Main");
Click("#ListCreate");
With();
Check("#Method", "Cash");