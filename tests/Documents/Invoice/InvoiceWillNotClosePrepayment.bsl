// Make Payment
// Create Invoice
// Check if prepayment is still outstanding

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "27116C04" );
env = getEnv ( id );
createEnv ( env );

// Create Payment
Commando("e1cib/command/Document.Payment.Create");
With("Customer Payment (create)");
Set("#Customer", env.Customer);
Set("#Amount", env.Prepayment);
Click("#FormPostAndClose");

// Create Invoice
Commando("e1cib/command/Document.Invoice.Create");
With("Invoice (create)");
Set("#Customer", env.Customer);
table = Get("#Services");
Click("#ServicesAdd");
Set("#ServicesItem", env.Service);
Set("#ServicesQuantity", 1);
Set("#ServicesPrice", env.Price);
Click("#FormPostAndClose");

// Open report Accounts Receivable
p = Call ( "Common.Report.Params" );
p.Path = "Sales / Accounts Receivable";
p.Title = "Accounts Receivable";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Name = "Customer";
item.Value = env.Customer;
filters.Add ( item );

p.Filters = filters;
With ( Call ( "Common.Report", p ) );
CheckTemplate("#Result");

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Service", "Service " + ID );
	p.Insert ( "Price", 200 );
	p.Insert ( "Prepayment", 100 );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = Env.Customer;
	p.CloseAdvances = false;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	
	// *************************
	// Create Service
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	RegisterEnvironment ( id );
	
EndProcedure
