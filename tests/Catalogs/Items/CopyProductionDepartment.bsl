// Create Item1
// Add departments
// Copy Item1
// Check if departments were copied

Call ( "Common.Init" );
CloseAll ();

// Create Product1
Commando("e1cib/command/Catalog.Items.Create");
With();
id = Call ( "Common.GetID" );
Set("#Description", "Product1 " + id);
Click("#Product");
Click("#FormWrite");
Click("#DepartmentItemsCreate");
With();
Put("#Department", createDepartment ());
Click("#FormWriteAndClose");
With();

// Copy Product1
Click("#FormCopy");
With();
CheckState("#CopyInfo", "Visible");
Set("#Description", "Product2 " + id);

// Save and check copying
Click("#FormWrite");
count = Call("Table.Count", Get("#DepartmentItems"));
if ( count <> 1 ) then
	Stop( "One department should be copied" );
endif;

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