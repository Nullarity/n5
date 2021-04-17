// Create Product
// Check Product flag
// Set description, save and check adding a new department
// Complete adding

Call ( "Common.Init" );
CloseAll ();

// Create Product
Commando("e1cib/command/Catalog.Items.Create");
With();

// Check Productn flag
CheckState("#DepartmentItems", "Visible", false);
Click("#Product");
CheckState("#DepartmentItems", "Visible");
CheckState("#DepartmentItems", "Enable", false);

// Set description, save and check adding a new item
description = "Item " + Call ( "Common.GetID" );
Set("#Description", description);
Click("#FormWrite");
CheckState("#DepartmentItems", "Enable");
Click("#DepartmentItemsCreate");
With();
Check("#Item", description);

// Complete adding
Put("#Department", createDepartment ());
Click("#FormWriteAndClose");
With();
Click("#FormWriteAndClose");

&AtClient
Function createDepartment ()
	
	id = Call("Common.GetID");
	department = "Department " + id;
	p = Call ( "Catalogs.Departments.Create.Params");
	p.Description = department;
	p.Production = true;
	Call ( "Catalogs.Departments.Create", p);
	return department;
	
EndFunction