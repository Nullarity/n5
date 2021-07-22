// Create Vendor Invoice
// Create Range
// Post Vendor Invoice

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "A087");
env = getEnv(id);
createEnv(env);

// Create Vendor Invoice
Commando("e1cib/command/Document.VendorInvoice.Create");
table = Get("#ItemsTable");
Set("#Vendor", env.Vendor);
Set("#Warehouse", env.Warehouse);
Click("#ItemsTableAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantity", env.Quantity);
Set("#ItemsPrice", env.Price);
table.EndEditRow();
Activate("#ItemsRange").Create();
With();
Set("#Prefix", Right(id, 5));
Set("#Start", 1);
Set("#Finish", env.Quantity);
Set("#Length", 3);
Set("#ExpenseAccount", "7118");
Click("#WriteAndClose");
With();
Click("#FormPost");
Click("#FormReportRecordsShow");
With();
CheckTemplate("#TabDoc");

// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Warehouse", "Main");
	p.Insert("Item", "Item " + ID);
	p.Insert("Price", 1);
	p.Insert("Quantity", 300);
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params");
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p);
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item;
	p.Form = true;
	Call ( "Catalogs.Items.Create", p);
	
	RegisterEnvironment(id);
	
EndProcedure

