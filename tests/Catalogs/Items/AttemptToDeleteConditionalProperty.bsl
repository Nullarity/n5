Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

// *****************************************
// Open list and check deletion restrictions
// *****************************************

Commando ( "e1cib/list/Catalog.Items" );
With ( "Items" );
Clear ( "#WarehouseFilter" );
GotoRow ( "#List", "Description", Env.Item );
Click ( "#FormChange" );
With ( Env.Item + " *" );
Click ( "#OpenObjectUsage" );
With ( "Properties" );
table = Get ( "#Tree" );
GotoRow ( table, "Description", "Field1" );
Click ( "#TreeDelete" );
Click ( "OK", DialogsTitle );
GotoRow ( table, "Description", "Field2" );
Click ( "#TreeDelete" );
Click ( "OK", DialogsTitle );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "275D3C77#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Item", "_Item: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	createItem ( Env );

	RegisterEnvironment ( id );

EndProcedure

Procedure createItem ( Env )

	Commando ( "e1cib/data/Catalog.Items" );
	
	With ( "Items (cr*" );
	Set ( "#Description", Env.Item );
	Pick ( "#ObjectUsage", "Current Object Settings" );
	Click ( "#OpenObjectUsage" );
	Click ( "Yes", DialogsTitle );
	
	With ( "Properties" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field1" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field2" );
	Click ( "#FormSave" );
	Activate ( "#PageConditions" );
	Click ( "#ConditionsCreate" );
	With ( "Property Conditions (create)" );
	Click ( "#ConditionsAdd" );
	Put ( "#ConditionsProperty", "Field1" );
	Activate ( "#ConditionsValue" );
	Set ( "#ConditionsValue", "1" );
	Click ( "#PropertiesAdd" );
	Put ( "#PropertiesProperty", "Field2" );
	Click ( "#FormWriteAndClose" );

	CloseAll ();


EndProcedure
