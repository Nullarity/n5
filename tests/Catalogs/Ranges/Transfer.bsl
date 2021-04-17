// Purchase forms an register range
// Transfer range to new location
// Do some testing: 1) empty range 2) many warehouses
// Post and check

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2A0E2097");
env = getEnv(id);
createEnv(env);

Commando("e1cib/command/Document.Transfer.Create");
Set("#Sender", env.Warehouse1);
Set("#Receiver", env.Warehouse2);
Click("#ItemsTableAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantity", 5);
range = "Invoice Records " + env.FormPrefix;
Set("#ItemsTableRange", range);
Next();

// Do some testing: 1) empty range
Clear("#ItemsTableRange");
Click("#FormPost");
Click("OK", "1?:*");
try
	CheckErrors();
	Stop("The message: <Range is not defined> should appear");
except
endtry;

// Do some testing: 2) many warehouses
range = "Invoice Records " + env.FormPrefix;
Set("#ItemsTableRange", range);
Click("#ItemsTableCopy");
table = Get("#ItemsTable");
Set("#ItemsSender [ 2 ]", env.Warehouse2, table); // Initially wrong warehouse
Click("#FormPost");
Click("OK", "1?:*");
try
	CheckErrors();
	Stop("The message: <Range is not defined> should appear");
except
endtry;

// Remove double, post & check document 
Click("#ItemsTableDelete");
Set("#ItemsSender [ 1 ]", env.Warehouse1, table);
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
	p.Insert("FormPrefix", Right(ID, 5));
	
	p.Insert("Vendor", "Vendor " + ID);
	p.Insert("Warehouse1", "Main");
	p.Insert("Warehouse2", "Warehouse " + ID);
	p.Insert("Item", "Item " + ID);
	p.Insert("Price", 1);
	p.Insert("Quantity", 5);
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
	// Create Warehouse2
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params");
	p.Description = Env.Warehouse2;
	Call ( "Catalogs.Warehouses.Create", p);
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item;
	p.Form = true;
	Call ( "Catalogs.Items.Create", p);
	
	// *********************
	// Create Vendor Invoice
	// *********************
	
	Commando("e1cib/command/Document.VendorInvoice.Create");
	table = Get("#ItemsTable");
	Set("#Vendor", env.Vendor);
	Set("#Warehouse", env.Warehouse1);
	Click("#ItemsTableAdd");
	Set("#ItemsItem", env.Item);
	Set("#ItemsQuantity", env.Quantity);
	Set("#ItemsPrice", env.Price);
	table.EndEditRow();
	field = Activate("#ItemsRange");
	field.OpenDropList();
	field.Create();
	With();
	Set("#Prefix", env.FormPrefix);
	Set("#Start", 1);
	Set("#Finish", env.Quantity);
	Set("#Length", 3);
	Set("#ExpenseAccount", "7118");
	Click("#WriteAndClose");
	With();
	Click("#FormPostAndClose");
	Pause(1); // Avoiding receive and split in one second
	
	RegisterEnvironment(id);
	
EndProcedure

