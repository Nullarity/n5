// Purchase forms an register range
// Create Write Off with range
// Do some testing: 1) empty range
// Post and check

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "2A0E20CE");
env = getEnv(id);
createEnv(env);

Commando("e1cib/command/Document.WriteOff.Create");
Set("#Warehouse", env.Warehouse);
Set("#ExpenseAccount", "7118");

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

// Post & check
range = "Invoice Records " + env.FormPrefix;
Set("#ItemsTableRange", range);

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
	p.Insert("Warehouse", "Main");
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
	Set("#Warehouse", env.Warehouse);
	Click("#ItemsTableAdd");
	Set("#ItemsItem", env.Item);
	Set("#ItemsQuantity", env.Quantity);
	Set("#ItemsPrice", env.Price);
	table.EndEditRow();
	Activate("#ItemsRange").Create();
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

