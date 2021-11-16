// Create Payment
// Create Invoice base on payment
// Check if invoice has been applied prepayment

Call("Common.Init");
CloseAll();

this.Insert("ID", Call("Common.ScenarioID", "A0F3"));
getEnv();
createEnv();

// Create payment
Commando("e1cib/command/Document.Payment.Create");
Set("#Customer", this.Customer);
Set("#Amount", 1000);
Click("#FormPostAndClose");

// Create Invoice
Commando("e1cib/command/Document.Invoice.Create");
Set("#Customer", this.Customer);
Services = Get("#Services");
Click("#ServicesAdd");
Put("#ServicesItem", this.Service, Services);
Set("#ServicesQuantity", 1, Services);
Set("#ServicesPrice", "1000.000", Services);
Next();
Click("#FormPost");

// Check Payments Applied
try
	Assert(0 + Fetch("#PaymentsApplied")).Equal(1000); // Advance payment should be taken right away
except
	DebugStart ();
endtry;
balanceDue = 0 + Fetch("#BalanceDue");
Assert(balanceDue).Equal(0);

// Change taxes and check if Balance Due changed
Put("#VATUse", "Excluded from Price");
Assert(0 + Fetch("#BalanceDue")).NotEqual(balanceDue);

// Check postings
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Procedure getEnv()
	
	id = this.ID;
	this.Insert("Customer", "Customer " + id);
	this.Insert("Service", "Service " + id);
	
EndProcedure

Procedure createEnv()
	
	id = this.ID;
	if (EnvironmentExists(id)) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params");
	p.Description = this.Customer;
	p.SkipAddress = true;
	Call ( "Catalogs.Organizations.CreateCustomer", p);
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params");
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p);
	
	RegisterEnvironment(id);
	
EndProcedure

