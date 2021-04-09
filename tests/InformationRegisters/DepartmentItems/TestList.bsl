// Open DepartmentItems list
// Set filter by product
// Clear department filter

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/list/InformationRegister.DepartmentItems");
With();
Clear("#DepartmentFilter");
Put("#ItemFilter", createItem ());

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