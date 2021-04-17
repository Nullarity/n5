// Create Warehouse
// Click Production flag and check appearance

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.Warehouses.Create");
With();
CheckState("#Department", "Visible", false);
Click("#Production");
CheckState("#Department", "Visible");
Click("#Production");
