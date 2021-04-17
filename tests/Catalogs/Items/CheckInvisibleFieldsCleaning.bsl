Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
createEnv ( env );

Commando ( "e1cib/list/Catalog.Items" );
With ( "Items" );
Clear ( "#WarehouseFilter" );
GotoRow ( "#List", "Description", Env.Item );
Click ( "#FormChange" );
With ( Env.Item + " *" );

Set ( "Field1", 1 );
Next (); // Field2 should appear
Set ( "Field2", "Some Value" );
Next ();

Set ( "Field1", 2 );
Next (); // Field2 should disappear

Set ( "Field1", 1 );
Next (); // Field2 should appear again with default value
Check ( "Field2", "Default Value" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "275D3CC0#" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Item", "_Item: " + id );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	createItem ( Env );

	Call ( "Common.StampData", id );

EndProcedure

Procedure createItem ( Env )

	Commando ( "e1cib/data/Catalog.Items" );
	
	With ( "Items (cr*" );
	Set ( "#Description", Env.Item );
	Pick ( "#ObjectUsage", "Current Object Settings" );
	Click ( "#OpenObjectUsage" );
	Click ( "Yes", DialogsTitle );
	
	// ***************************
	// Create Fields
	// ***************************

	With ( "Properties" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field1" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field2" );
	Set ( "#TreeDefaultValue", "Default Value" );
	
	Click ( "#FormSave" );
	
	// ***************************
	// Create condition for Field2
	// ***************************
	
	Activate ( "#PageConditions" );
	Click ( "#ConditionsCreate" );
	With ( "Property Conditions (create)" );
	Click ( "#ConditionsAdd" );
	Put ( "#ConditionsProperty", "Field1" );
	Activate ( "#ConditionsOperator" );
	Set ( "#ConditionsOperator", "=" );
	Activate ( "#ConditionsValue" );
	Set ( "#ConditionsValue", "1" );
	Click ( "#PropertiesAdd" );
	Put ( "#PropertiesProperty", "Field2" );
	Click ( "#FormWriteAndClose" );

	CloseAll ();

EndProcedure
