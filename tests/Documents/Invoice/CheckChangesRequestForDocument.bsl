// Will send a simple request for opening a day for changes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0OZ" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region sendrequest
Call ( "Documents.Invoice.ListByMemo", id );
With ();
Click ( "#FormChange" );
With ();
Get ( "#AccessLabel").ClickFormattedStringHyperlink ( "Apply for authorization of the operation" );
With ();
Click ( "#Button2" ); // OK
With ();
Click ( "#FormOK" );
#endregion

#region selfallowing
With ();
Get ( "#AccessLabel").ClickFormattedStringHyperlink ( "Request sent, await resolution" );
With ();
Set ( "#Resolution", "Allow" );
Click ( "#FormOK" );
With ();
warning = Get ( "#AccessLabel" ).TitleText;
Assert ( warning ).Contains ( "been temporarily removed" );
#endregion

Click ( "#FormPostAndClose" );

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Date", Date ( 2017, 3, 2 ) );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createService
	p = Call("Catalogs.Items.Create.Params");
	p.Description = this.Service;
	p.Service = true;
	Call("Catalogs.Items.Create", p);
	#endregion

	#region createInvoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Customer", this.Customer);
	Put("#Date", this.Date);
	Put("#Memo", id);
	Pick ( "#VATUse", "Not Applicable" );
	Services = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	Services.EndEditRow ();
	Set ( "#ServicesItem", this.Service, Services );
	Set ( "#ServicesQuantity", 1, Services );
	Set ( "#ServicesPrice", 300, Services );
	Click ( "#JustSave" );
	Close ();
	#endregion

	#region setAccess
	OpenMenu ( "Sections panel / Settings" );
	OpenMenu ( "Functions menu / Users / Access to Documents" );
	With ( "Access to Documents" );
	Click ( "#FormCreate" );
	With ( "Rights (create)" );
	Set ( "#Access", "Deny" );
	Set ( "#DateStart", this.Date );
	Next ();
	Set ( "#DateEnd", EndOfDay ( this.Date ) );
	Next ();
	Click ( "#FormWriteAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
