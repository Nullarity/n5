// Create payments in different currencies and check results

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "2A4567B1"));
getEnv();
createEnv();

// Payment: MDL -> MDL
Commando("e1cib/command/Document.Payment.Create");
Set("#Customer", this.Customer);
Set("#Amount", 100);
Next();
Activate("#GroupCurrency");
CheckState("#Rate, #Factor, #ContractRate, #ContractFactor", "Enable", false);

// Payment: MDL -> USD
Put("#Currency", "USD");
CheckState("#Rate, #Factor", "Enable");
CheckState("#ContractRate, #ContractFactor", "Enable", false);

// Payment: USD -> MDL
Put("#Contract", "USD Contract");
CheckState("#Rate, #Factor", "Enable", false);
CheckState("#ContractRate, #ContractFactor", "Enable");

// Payment: USD -> CAD
Put("#Currency", "CAD");
CheckState("#Rate, #Factor, #ContractRate, #ContractFactor", "Enable", true);

// *************************
// Procedures
// *************************

Procedure getEnv()
	
	id = this.ID;
	this.Insert("Customer", "Customer " + id);
	
EndFunction

Procedure createEnv()
	
	id = this.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *********************************
	// Create customer and two contracts
	// *********************************
	
	Commando("e1cib/command/Catalog.Organizations.Create");
	Click("#Customer");
	Set("#Description", this.Customer);
	Click("#FormWrite");
	Click("Contracts", GetLinks());
	With();
	Click("#FormCreate");
	With();
	Set("#Description", "USD contract");
	Set("#Currency", "USD");
	Click("#FormWriteAndClose");
	
	RegisterEnvironment(id);
	
EndProcedure

