// Create PO
// Create VendorInvoice and check if Balance Due is calculated

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "2B252ACF"));
getEnv();
createEnv();

// Create PO
Commando("e1cib/command/Document.PurchaseOrder.Create");
Set("#Vendor", this.Vendor);
Next ();
Assert(0 + Fetch("#BalanceDue")).Equal(0);
Assert(0 + Fetch("#PaymentsApplied")).Equal(0);
Items = Get("#ItemsTable");
Click("#ItemsTableAdd");
Put("#ItemsItem", this.Item, Items);
Set("#ItemsQuantityPkg", 1, Items);
Set("#ItemsPrice", "1,000.000", Items);
Click("#FormPost");
Assert(0 + Fetch("#BalanceDue")).Greater(0);
Assert(0 + Fetch("#PaymentsApplied")).Equal(0);

// Create Payment
Click("#CreatePayment");
With ();
Click ( "#FormPostAndClose" );

// Check Payments Applied
With ();
Assert(0 + Fetch("#BalanceDue")).Equal(0);
Assert(0 + Fetch("#PaymentsApplied")).Greater(0);

// Change VATUse influence on BalanceDu
Put("#VATUse", "Excluded from Price");
Assert(0 + Fetch("#BalanceDue")).Greater(0);
Assert(0 + Fetch("#PaymentsApplied")).Greater(0);

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

