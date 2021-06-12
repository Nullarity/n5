// Create VendorPayment
// Create VendorInvoice base on payment
// Check if vendor invoice has been applied prepayment

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "A02B"));
getEnv();
createEnv();

// Create payment
Commando("e1cib/command/Document.VendorPayment.Create");
Set("#Vendor", this.Vendor);
Set("#Amount", 1000);
Click("#FormPostAndClose");

// Create VendorInvoice
Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Items = Get("#ItemsTable");
Click("#ItemsTableAdd");
Put("#ItemsItem", this.Item, Items);
Set("#ItemsQuantityPkg", 1, Items);
Set("#ItemsPrice", "1,000.000", Items);

Next();
Click("#FormPost");

// Check Payments Applied
Assert(0 + Fetch("#PaymentsApplied")).Greater(0);
balanceDue = 0 + Fetch("#BalanceDue");
Assert(balanceDue).Equal(0); // Advance should be taken right away

// Change taxes and check if Balance Due changed
Put("#VATUse", "Excluded from Price");
Assert(0 + Fetch("#BalanceDue")).NotEqual(balanceDue);

// *************************
// Procedures
// *************************

Procedure getEnv()
	
	id = this.ID;
	this.Insert("Vendor", "Vendor " + id);
	this.Insert("Item", "Item " + id);
	
EndProcedure

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

