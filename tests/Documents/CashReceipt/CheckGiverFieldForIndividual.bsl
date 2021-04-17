// Receive payment from individual and check if "Received from" field is correct

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CF29AAA" ) );
getEnv ();
createEnv ();

Commando("e1cib/command/Document.Payment.Create");
Set ( "!Customer", this.FirstName );
Set ( "!Amount", 100 );
Set ( "!Method", "Cash" );
Next();
Click ( "!NewReceipt" );
With ( "Cash Receipt" );
Check ( "!Giver", this.FirstName + " " + this.LastName );

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "FirstName", "First_" + id );
	this.Insert ( "LastName", "Last" );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	Commando("e1cib/command/Catalog.Organizations.Create");
	Click ( "!Customer" );
	Click ( "!Individual" );
	Set ( "!FirstName", this.FirstName );
	Set ( "!LastName", this.LastName );
	Click ( "!FormWriteAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
