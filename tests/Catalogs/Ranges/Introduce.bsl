// Create Item Balances
// Create Range
// Post Item Balances
// Post again because it has non-standard date for its records
// Change the quantity and check if error message occurs

Call("Common.Init");
CloseAll();

id = Call("Common.ScenarioID", "293C9D48");
env = getEnv(id);
createEnv(env);

// Create Vendor Invoice
Commando("e1cib/list/DocumentJournal.Balances");
date = Fetch("#BalanceDate");
if (Date(date) = Date(1, 1, 1)) then
	Set("#BalanceDate", Format(CurrentDate(), "DLF=D"));
	Next();
endif;
Click("#FormCreateByParameterItemBalances");
With();
Set("#Account", env.Account);
Set("#Warehouse", env.Warehouse);
table = Get("#Items");
Click("#ItemsAdd");
Set("#ItemsItem", env.Item);
Set("#ItemsQuantity", env.Quantity);
Set("#ItemsCost", env.Cost);
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

// Post second time for testing information register
Close();
With();
Click("#FormPost");

// Change the quantity and check if error message occurs
Set("#Items / #ItemsQuantity[1]", env.Quantity - 1);
Click("#FormPost");
Click("OK", "1?:*");
if (FindMessages("The size of *").Count() = 0) then
	Stop("Error message about wrong range size should appear");
endif;
Set("#Items / #ItemsQuantity[1]", env.Quantity);
Click("#FormPost");

// *************************
// Procedures
// *************************

Function getEnv(ID)
	
	p = new Structure();
	p.Insert("ID", ID);
	p.Insert("Warehouse", "Main");
	p.Insert("Item", "Item " + ID);
	p.Insert("Cost", 1);
	p.Insert("Quantity", 300);
	p.Insert("Account", "2171");
	return p;
	
EndFunction

Procedure createEnv(Env)
	
	id = Env.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = Env.Item;
	p.Form = true;
	Call ( "Catalogs.Items.Create", p);
	
	RegisterEnvironment(id);
	
EndProcedure

