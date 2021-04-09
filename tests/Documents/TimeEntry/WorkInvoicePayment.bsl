// Create time entry (services only)
// Generate Invoice
// Generate Payment
// Print Invoice

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2BDC5DF9" ) );
getEnv ();
createEnv ();

Call ( "Common.NewSession", this.Worker );

// Create time entry (services only)
Commando("e1cib/command/Document.TimeEntry.Create");
Set ( "#Customer", this.Customer );
Tasks = Get ( "#Tasks" );
Click ( "#TasksAdd" );
Set ( "#TasksTimeStart", "01:00", Tasks );
Set ( "#TasksTimeEnd", "02:00", Tasks );
Click ( "#FormPost" );

// Generate Invoice
Click ( "#CreateInvoice" );
With ();
Pause ( 2 );
Assert ( 0 + Fetch ( "#Amount" ) ).Greater ( 0 );

// Generate Payment
Click("#CreatePayment");
Click("OK", "1?:*");
With();
Click("#FormPostAndClose");

// Print Invoice
With();
Click("#FormDocumentInvoiceInvoice");

Disconnect ( true );

// *************************
// Procedures
// *************************

Procedure getEnv ()
	
	id = this.ID;
	this.Insert ( "Worker", "Worker " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );
	this.Insert ( "Task", "Task " + id );
	this.Insert ( "HourlyRate", 100 );
	this.Insert ( "Project", "Project " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Customer
	// *************************
	
	p = Call ( "Catalogs.Customers.Create.Params" );
	p.Name = this.Customer;
	Call ( "Catalogs.Customers.Create", p );

	// *************************
	// Create Worker
	// *************************
	
	p = Call ( "Catalogs.Users.Create.Params" );
	p.Name = this.Worker;
	p.Organizations.Add ( this.Customer );
	p.Rights.Add ( "Customers / Invoices, Edit" );
	p.Rights.Add ( "Customers / Payment, Edit" );
	p.Rights.Add ( "Timesheets / Timesheets, Edit" );
	p.Rights.Add ( "Sections / Time Subsystem" );
	p.Rights.Add ( "Sections / Sales Subsystem" );
	Call ( "Catalogs.Users.Create", p );

	// *************************
	// Create Item
	// *************************
	 
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );

	// *************************
	// Create Task
	// *************************
	
	Commando("e1cib/command/Catalog.Tasks.Create");
	Set ( "#Description", this.Task );
	Set ( "#Item", this.Item );
	Click("#FormWriteAndClose");

	// *************************
	// Create Project
	// *************************
	
	Commando("e1cib/command/Catalog.Projects.Create");
	Set ( "#Owner", this.Customer );
	Set ( "#Description", this.Project );
	Set ( "#DateStart", Format ( CurrentDate (), "DLF=D" ) );
	Tasks = Get ( "#Tasks" );
	Click ( "#TasksAdd" );
	Set ( "#TasksEmployee", this.Worker, Tasks );
	Set ( "#TasksTask", this.Task, Tasks );
	Set ( "#TasksHourlyRate", this.HourlyRate, Tasks );
	Click("#FormWriteAndClose");

	RegisterEnvironment ( id );

EndProcedure
