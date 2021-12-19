// Scenario:
// - Create a new Individual
// - Add birth certificate & set is as Main
// - Add passport & set is as Main
// - Check that birth certificate is not main anymore

Call ( "Common.Init" );
CloseAll ();

// Create Individual
Commando ( "e1cib/data/Catalog.Individuals" );
form = With ( "Individuals (cr*" );
id = Call ( "Common.GetID" );
Set ( "#FirstName", id );
Set("#Code", "88888" + TestingID ());
Click("Yes", "1?:*");
Click ( "#FormWrite" );

Click ( "IDs", GetLinks () );
list = With ( "IDs" );

// Create Birth Certificate
Click ( "#FormCreate" );
With ( "Identity Documents (cr*" );

Set ( "#Type", "Birth Certificate" );
Set ( "#Period", "2/1/2012" );
Click ( "#FormWriteAndClose" );

With ( list );
Click ( "#FormChange" );
Check ( "#Main", "Yes", "Identity Documents" );
Close ( "Identity Documents" );

// Create Passport
With ( list );
Click ( "#FormCreate" );
With ( "Identity Documents (cr*" );

Set ( "#Type", "Passport" );
Set ( "#Period", "2/1/2012" );
Click ( "#FormWriteAndClose" );

With ( list );
Click ( "#FormChange" );
Check ( "#Main", "Yes", "Identity Documents" );
Close ( "Identity Documents" );

// Check that birth certificate is not main anymore 
GotoRow ( "#List", "Type", "Birth Certificate" );
Click ( "#FormChange" );
Check ( "#Main", "No", "Identity Documents" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "FirstName", ID );
	p.Insert ( "LastName", "L_" + ID );
	p.Insert ( "Patronymic", "P_" + ID );
	p.Insert ( "FullName", ID + " " + p.Patronymic +  " " + p.LastName );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Individual
	// *************************
	
	Commando ( "e1cib/data/Catalog.Individuals" );
	With ( "Individuals (cr*" );
	Set ( "#FirstName", Env.FirstName );
	Set ( "#LastName", Env.LastName );
	Set ( "#Patronymic", Env.Patronymic );
	Click ( "#FormWriteAndClose" );

	RegisterEnvironment ( id );

EndProcedure
