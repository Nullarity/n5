// Create document from list

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/list/Document.Sale");
Check("#WarehouseFilter", "Main");
Click("#FormCreate");
With();
Check("#Method", "Cash");