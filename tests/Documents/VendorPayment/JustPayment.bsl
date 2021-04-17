// Create a new Vendor
// Create a new Vendor Payment
// Fill Payment and post
// Check records

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "286CF580" );
env = getEnv ( id );
createEnv ( env );

// Create a new Payment
Commando ( "e1cib/data/Document.VendorPayment" );
With ( "Vendor Payment (cre*" );
Set ( "#Vendor", env.Vendor );
Set ( "#Amount", "100" );
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records: *" );

CheckTemplate ( "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Vendor", "Vendor " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );

	RegisterEnvironment ( id );

EndProcedure
