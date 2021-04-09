// Create Non-taxable Vendor Invoice and check if the process
// of entering data takes into account the Non-taxable setting

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "2A47F48B"));
getEnv();
createEnv();

Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Set("#TaxCode", "Non-Taxable Sales");
Set("#TaxGroup", "GST + PST (Quebec)");
Click("#ItemsTableAdd");
Put("#ItemsItem", this.Item);
Next();
Check("#ItemsTable / #ItemsTaxCode", "Non-Taxable Sales");
Set("#ItemsTable / #ItemsAmount", 100);
Check("#Tax", 0);

// *************************
// Procedures
// *************************

Procedure getEnv()
	
	id = this.ID;
	this.Insert("Vendor", "Vendor " + id);
	this.Insert("Item", "Item " + id);
	
EndFunction

Procedure createEnv()
	
	id = this.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params");
	p.Description = this.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p);
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p);
	
	RegisterEnvironment(id);
	
EndProcedure

