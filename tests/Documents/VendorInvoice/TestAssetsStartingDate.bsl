
Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorInvoice" );
form = With ( "Vendor Invoice (cr*" );
Set ( "#Vendor", env.Vendor );
Next ();

for i = 0 to 1 do
	if ( i = 0 ) then
		table = Activate ( "#FixedAssets" );
		Click ( "#FixedAssetsAdd", table );
		With ( "Fixed Asset" );
		Set ( "#Item", env.FixedAsset );
	else
		table = Activate ( "#IntangibleAssets" );
		Click ( "#IntangibleAssetsAdd", table );
		With ( "Intangible Asset" );
		Set ( "#Item", env.IntangibleAsset );
	endif;

	Set ( "#Department", "Administration" );
	Click ( "#Charge" );
	Clear ( "#Starting" );
	Click ( "#FormOK" );
	With ( form );
	IgnoreErrors = true;
	Click ( "#FormPost" );
	Call ( "Common.FillCheckError", "Calculation *" );
	Call ( "Table.Clear", table );
	Click ( "#FormWrite" );
	IgnoreErrors = false;
enddo;

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "618114489#" );
	env = new Structure ();
	env.Insert ( "ID", id );
	env.Insert ( "Vendor", "_Test Assets " + id );
	env.Insert ( "FixedAsset", "_Asset " + id );
	env.Insert ( "IntangibleAsset", "_Int Asset " + id );
	return env;

EndFunction

Procedure createEnv ( env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = Env.Vendor;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	
	p = Call ( "Catalogs.FixedAssets.Create.Params" );
	p.Description = env.FixedAsset;
	Call ( "Catalogs.FixedAssets.Create", p );
	
	p = Call ( "Catalogs.IntangibleAssets.Create.Params" );
	p.Description = env.IntangibleAsset;
	Call ( "Catalogs.IntangibleAssets.Create", p );

	RegisterEnvironment ( id );

EndProcedure
