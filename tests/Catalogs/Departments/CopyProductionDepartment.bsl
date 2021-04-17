// Create Department1
// Add products
// Copy Department1
// Check if products were copied

Call ( "Common.Init" );
CloseAll ();

// Create Department1
Commando("e1cib/command/Catalog.Departments.Create");
With();
id = Call ( "Common.GetID" );
Set("#Description", "Department1 " + id);
Click("#Production");
Click("#FormWrite");
Click("#DepartmentItemsCreate");
With();
Put("#Item", createItem ());
Click("#FormWriteAndClose");
With();

// Copy Department1
Click("#FormCopy");
With();
CheckState("#CopyInfo", "Visible");
Set("#Description", "Department2 " + id);

// Save and check copying
Click("#FormWrite");
count = Call("Table.Count", Get("#DepartmentItems"));
if ( count <> 1 ) then
	Stop( "One product should be copied" );
endif;

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