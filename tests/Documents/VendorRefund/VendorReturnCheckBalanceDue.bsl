// Create VendorInvoice & Payment
// Create VendorReturn & VendorRefund and check Balance Due

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "A0VU"));
getEnv();
createEnv();

#region CreateVendorInvoice

Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Next ();
Items = Get("#ItemsTable");
Click("#ItemsTableAdd");
Put("#ItemsItem", this.Item, Items);
Set("#ItemsQuantityPkg", 1, Items);
Set("#ItemsPrice", "1,000.000", Items);
Click("#FormPost");

#endregion

#region CreatePayment

Click("#CreatePayment");
With ();
Set ( "#Amount", 1000 );
Click ( "#FormPostAndClose" );

#endregion

#region CreateVendorReturn

With ();
Click("#FormDocumentVendorReturnCreateBasedOn");
With();
Assert(0 + Fetch("#BalanceDue")).Greater(0);
Assert(0 + Fetch("#PaymentsApplied")).Equal(0);
Click("#FormPost");
Assert(0 + Fetch("#BalanceDue")).Greater(0);
Assert(0 + Fetch("#PaymentsApplied")).Equal(0);
Click("#CreatePayment");
With();
Set ( "#Amount", 1000 );
Click("#FormPostAndClose");
With();
Assert(0 + Fetch("#BalanceDue")).Equal(0);
Assert(0 + Fetch("#PaymentsApplied")).Greater(0);

#endregion

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

