﻿// Create PO
// Create VendorInvoice and check if Balance Due is calculated

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "A0UO"));
getEnv();
createEnv();

// Create PO
Commando("e1cib/command/Document.PurchaseOrder.Create");
Set("#Vendor", this.Vendor);
Items = Get("#ItemsTable");
Click("#ItemsTableAdd");
Put("#ItemsItem", this.Item, Items);
Set("#ItemsQuantityPkg", 1, Items);
Set("#ItemsPrice", "1,000.000", Items);
Click("#FormPostAndClose");

// Create VendorInvoice
Commando("e1cib/command/Document.VendorInvoice.Create");
Set("#Vendor", this.Vendor);
Next ();

// Check Payments Applied
Assert(0 + Fetch("#BalanceDue")).Greater(0);
balanceDue = 0 + Fetch("#BalanceDue");
Assert(balanceDue).Greater(0);

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

