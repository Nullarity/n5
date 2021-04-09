// Create an Event

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2BDB418E" ) );
getEnv ();
createEnv ();

#region CreateEvent

Commando ( "e1cib/command/Document.Event.Create" );

tomorrow = CurrentDate () + 86400;
Set ( "#Start", Format ( tomorrow, "DLF=D" ) + " 10:00:00 AM" );
Set ( "#Finish", Format ( tomorrow, "DLF=D" ) + " 11:30:00 AM" );
Next ();
Assert ( Fetch ( "#Duration" ) ).Equal ( "1h.30m." );

Set ( "#Organization", this.Customer );
Next ();
Assert ( Fetch ( "#Contract" ) ).Filled ();
Set ( "#Subject", "test" );
Set ( "#Content", "test" );
Set ( "#Reminder", "1h" );
Click ( "#FormWriteAndClose" );
CheckErrors ();

#endregion

#region CreateTimeEntry

Commando("e1cib/list/DocumentJournal.Customers");
customer = this.Customer;
Set("#CustomerFilter", customer);
Next ();
Click ( "#ListContextMenuChange" );
With ();
Click ( "#CreateTimeEntry" );
With ();

Activate ( "#Project" ).Create ();
With ();
Set ( "#Description", "Test" );
Set ( "#DateStart", " 1/1/2020" );
Click ( "#FormWriteAndClose" );
With();
Click("#FormPostAndClose");
With();
CheckState("#Links", "Visible");

#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );

	RegisterEnvironment ( id );

EndProcedure
