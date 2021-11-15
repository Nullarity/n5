Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "285E3E5A#" );

env = getEnv ( id );
createEnv ( env );

// *******************************************
// Field2 should be visible only if Field1 = 1
// *******************************************

Commando ( "e1cib/list/Catalog.Items" );
With ( "Items" );
Clear ( "#WarehouseFilter" );
GotoRow ( "#List", "Description", Env.Item );
Click ( "#FormChange" );
With ( Env.Item + " *" );

CheckState ( "Field2", "Visible", false );
Set ( "Field1", id );
Set ( "Field3", 8 );
Next ();
CheckState ( "Field2", "Visible", false );
Check ( "#Description", id + ", 8" );
Check ( "#FullDescription", id + ", 8" );

Click ( "#FormWrite" );

Set ( "Field1", 1 );
Next ();
CheckState ( "Field2", "Visible" );
CheckState ( "Field3", "Visible", false );
Set ( "Field2", 2 );
Next ();
Check ( "#Description", "1, 2" );
Check ( "#FullDescription", "1, 2" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "_Item: " + ID );
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
	
	// ***************************
	// Create Fields
	// ***************************

	With ( "Properties" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field1" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field2" );
	Click ( "#Add" );
	Set ( "#TreeName", "Field3" );
	
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

	// ***************************
	// Create condition for Field3
	// ***************************

	With ( "Properties" );
	Click ( "#ConditionsCreate" );
	With ( "Property Conditions (create)" );
	Click ( "#ConditionsAdd" );
	Put ( "#ConditionsProperty", "Field1" );
	Activate ( "#ConditionsOperator" );
	Set ( "#ConditionsOperator", "<>" );
	Activate ( "#ConditionsValue" );
	Set ( "#ConditionsValue", "1" );
	Click ( "#PropertiesAdd" );
	Put ( "#PropertiesProperty", "Field3" );
	Click ( "#FormWriteAndClose" );

	CloseAll ();

EndProcedure
