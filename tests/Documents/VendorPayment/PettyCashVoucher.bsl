Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "25BA46CA" );
env = getEnv ( id );
createEnv ( env );

// **********************
// Create Vendor Payment
// **********************

Commando ( "e1cib/command/Document.VendorPayment.Create" );
form = With ( "Vendor Payment (cr*" );

Put ( "#Vendor", env.Vendor );
Pick ( "#Method", "Cash" );
Set ( "#Amount", "300" );
Click ( "#NewVoucher" );

// **********************
// Vaucher
// **********************

With ( "Cash Voucher" );
Set ( "#Reason", "Reason" );
Set ( "#Reference", "Reference" );

// Check values
Check ( "#Receiver", env.Vendor );

if ( Fetch ( "#Responsible" ) = "" ) then
	Stop ( "Responsible should be filled" );
endif;
if ( Fetch ( "#Accountant" ) = "" ) then
	Stop ( "Accountant chied should be filled" );
endif;
if ( Fetch ( "#Director" ) = "" ) then
	Stop ( "Director should be filled" );
endif;

// Save Voucher
Click ( "#FormOK" );

// Save Vendor Payment
With ( form );
Click ( "#FormWrite" );


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
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Vendor
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );

	Call ( "Common.StampData", id );

EndProcedure
