// Create Item
// Click BOM link and check list

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
Click("BOM", GetLinks());
With();
CheckState("#ItemFilter", "Visible", false);
Click("#FormCreate");
With();
Check("#Item", item);