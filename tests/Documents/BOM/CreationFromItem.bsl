// Create Item
// Create BOM from item and check filling process

Call ( "Common.Init" );
CloseAll ();

// Create Item
id = Call ("Common.GetID");
item = "Item " + id;
Commando("e1cib/command/Catalog.Items.Create");
With();
Set("#Description", item);
Click("#Product");
Click("#FormWrite");

// Create BOM
Activate("#BOM").Create();
With();
Check("#Item", item);
Check("#Description", item);
