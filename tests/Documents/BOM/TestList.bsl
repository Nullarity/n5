// Create Item
// Open BOM list
// Set filter
// Create BOM

Call ( "Common.Init" );
CloseAll ();

// Create Item
id = Call ("Common.GetID");
item = "Item " + id;
Commando("e1cib/command/Catalog.Items.Create");
With();
Set("#Description", item);
Click("#Product");
Click("#FormWriteAndClose");

// Open list
Commando("e1cib/list/Catalog.BOM");
With();
Set ("#ItemFilter", item);
Next();
Click("#FormCreate");
With();
Check("#Item", item);
