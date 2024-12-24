// Create two customers and replace one to another

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A1B5" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region findLinks
Commando ( "e1cib/app/DataProcessor.FindAndReplace" );
Pause ( 1 );
With ();
Clear ( "#Find" );
Choose ( "#Find" );
With ( "Select data type" );
Table = Get ( "#TypeTree" );
GotoRow ( Table, "", "Organizations" );
Click ( "OK" );
With ();
Close ();
With ();
Put ( "#Find", this.Customer1 );
Pause ( 1 );
With ();
Put ( "#Replace", this.Customer2 );
Assert ( Call ( "Table.Count", Get ( "#Links" ) ) ).Greater ( 0 );
#endregion

#region replaceValues
Click ( "#FormReplace" );
With ();
Click ( "#Button0" ); // Yes
Pause ( 2 );
With ();
Assert ( Call ( "Table.Count", Get ( "#Links" ) ) ).Equal ( 0 );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer1", "Customer1 " + id );
	this.Insert ( "Customer2", "Customer2 " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createCustomers
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer1;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	p.Description = this.Customer2;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
