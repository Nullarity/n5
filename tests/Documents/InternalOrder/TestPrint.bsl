// Create and print Internal Order

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2D288B42" ) );
getEnv ();
createEnv ();

Commando("e1cib/list/Document.InternalOrder");
p = Call("Common.Find.Params");
p.Where = "Memo";
p.What = this.ID;
Call("Common.Find", p);
Click ( "#FormDataProcessorPrintInternalOrder" );
With ();
Put("#Language", "Default");
Click("#FormOK");
With();
CheckTemplate ( "#TabDoc" );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Warehouse", "Warehouse " + id );
	this.Insert ( "Item1", "Item1 " + id );
	this.Insert ( "Item2", "Item2 " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region createWarehouse
	p = Call ( "Catalogs.Warehouses.Create.Params" );
	p.Description = this.Warehouse;
	Call ( "Catalogs.Warehouses.Create", p );
	#endregion

	#region createItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item1;
	Call ( "Catalogs.Items.Create", p );

	p.Description = this.Item2;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createInternalOrder
	Commando ( "e1cib/data/Document.InternalOrder" );
	With ();
	Put ( "#Warehouse", this.Warehouse );
	Put ( "#Memo", id );
	Put ( "#Responsible", "Director" );
	
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", this.Item1 );
	Activate ( "#ItemsFeature" ).Create ();
	With ();
	Set ( "#Description", Call ( "Common.GetID" ) );
	Click ( "#FormWriteAndClose" );
	
	With ();
	Items = Get ( "#ItemsTable" );
	
	Put ( "#ItemsPrice", "100" );
	Put ( "#ItemsQuantity", "5" );
	
	Click ( "#ItemsTableAdd" );
	Put ( "#ItemsItem", this.Item2 );
	Put ( "#ItemsPrice", "200" );
	Put ( "#ItemsQuantity", "10" );
	Set ( "#Memo", id );
	Click ( "#FormWrite" );
	Close ();
	#endregion

	RegisterEnvironment ( id );

EndProcedure
