// Create & register a new virtual range
// Transfer range to another warehouse

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A07Y" );
env = getEnv ( id );
createEnv ( env );

Commando("e1cib/command/Document.TransferRange.Create");
Set("#Range", env.Range);
Set("#Sender", env.Warehouse1);
Set("#Receiver", env.Warehouse2);
Click("#FormWrite");
Click("#FormShowRecords");
With("Reco*");
CheckTemplate("#TabDoc");

Disconnect();

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Warehouse1", "Warehouse1 " + id );
	p.Insert ( "Warehouse2", "Warehouse2 " + id );
	prefix = Right(ID, 5);
	p.Insert ( "Prefix", prefix );
	p.Insert ( "Range", "Invoice Records " + prefix );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Warehouse
	// *************************
	
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse1;
	Call ( "Catalogs.Warehouses.Create", p );

	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = Env.Warehouse2;
	Call ( "Catalogs.Warehouses.Create", p );
	
	// *************************************
	// Create & register a new virtual range
	// *************************************
	
	Commando("e1cib/list/Catalog.Ranges");
	Click("#FormCreate");
	With();
	Set("#Prefix", Env.Prefix);
	Set("#Start", 1);
	Set("#Finish", 30);
	Click("#WriteAndClose");
	With ("Enroll Range*");
	Set("#Warehouse", Env.Warehouse1);
	Click("#FormWriteAndClose");
	
	CloseAll();
	
	RegisterEnvironment ( id );
	
EndProcedure
