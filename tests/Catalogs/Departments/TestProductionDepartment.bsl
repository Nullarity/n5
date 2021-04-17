// Create Department
// Check Production flag
// Set description, save and check adding a new item
// Complete adding

Call ( "Common.Init" );
CloseAll ();

// Create Department
Commando("e1cib/command/Catalog.Departments.Create");
With();

// Check Production flag
CheckState("#DepartmentItems", "Visible", false);
Click("#Production");
CheckState("#DepartmentItems", "Visible");
CheckState("#DepartmentItems", "Enable", false);

// Set description, save and check adding a new item
description = Call ( "Common.GetID" );
Set("#Description", description);
Click("#FormWrite");
CheckState("#DepartmentItems", "Enable");
Click("#DepartmentItemsCreate");
With();
Check("#Department", description);

// Complete adding
Put("#Item", createItem ());
Click("#FormWriteAndClose");
With();
Click("#FormWriteAndClose");

&AtClient
Function createItem ()
	
	id = Call("Common.GetID");
	item = "Item " + id;
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = item;
	p.Product = true;
	Call ( "Catalogs.Items.Create", p);
	return item;
	
EndFunction