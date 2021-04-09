// Create, fill and post Invoice
// Create another one using Post & New button
// Open list form again and set filter by customer
// Open existed document
// Create another one using Post & New button and check if customer field is filled

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "284A8ABE" );
env = getEnv ( id );
createEnv ( env );

// Create, fill and post Invoice
Commando ( "e1cib/list/Document.Invoice" );
list = With ( "Invoices" );
Click ( "#FormCreate" );
With ( "Invoice (cr*" );
Put ( "#Customer", env.Customer );
Put ( "#Department", "Administration" );
Click ( "#ServicesAdd" );
Put ( "#ServicesItem", env.Service );
Set ( "#ServicesQuantity", 1 );
Set ( "#ServicesPrice", 1000 );

// Create another one using Post & New button
Click ( "#FormCommonCommandPostAndNew" );
Click ( "OK", "1?:*" );
With ( "Invoice (cr*" );
Close ();

// Open list form again and set filter by customer
With ( list );
Put ( "#CustomerFilter", env.Customer );

Click ( "#FormCreate" );
With ( "Invoice (cr*" );
Check ( "#Customer", env.Customer );

// Open existed document
//Click ( "#FormChange" );

// Create another one using Post & New button and check if customer field is filled
//Click ( "#FormCommonCommandNewDocument", "Invoice #*" );
//With ( "Invoice (cr*" );
//Check ( "#Customer", env.Customer );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Customer", "Customer " + ID );
	p.Insert ( "Service", "Service " + ID );
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
