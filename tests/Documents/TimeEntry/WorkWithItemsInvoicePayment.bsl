// Create time entry with services and materials
// Generate Invoice
// Generate Payment
// Print Invoice

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2BDC6E81" ) );
getEnv ();
createEnv ();

Call ( "Common.NewSession", this.Worker );

#region CreateTimeEntry

Commando("e1cib/command/Document.TimeEntry.Create");
Set ( "#Customer", this.Customer );
Tasks = Get ( "#Tasks" );
Click ( "#TasksAdd" );
Set ( "#TasksTimeStart", "01:00", Tasks );
Set ( "#TasksTimeEnd", "02:00", Tasks );

ItemsTable = Get ( "#ItemsTable" );
Click ( "#ItemsTableAdd" );
Set ( "#ItemsItem", this.Material, ItemsTable );
Set ( "#ItemsQuantityPkg", 3, ItemsTable );

Click ( "#FormPost" );
CheckErrors ();

#endregion

#region GenerateInvoice

Click ( "#CreateInvoice" );
With ();
Pause ( 2 );
Assert ( 0 + Fetch ( "#Amount" ) ).Greater ( 0 );
ItemsTable = Get ( "#ItemsTable" );
Set ( "#ItemsPrice", 200, ItemsTable );
total = Fetch("#Amount");

#endregion

#region GeneratePayment

Click("#CreatePayment");
Click("OK", "1?:*");
With();
Assert(Fetch("#Amount")).Equal(total);
Click("#FormPostAndClose");
CheckErrors();

#endregion

#region PrintInvoice

With();
Click("#FormDocumentInvoiceInvoice");

#endregion

Disconnect ( true );

// *************************
// Procedures
// *************************

Procedure getEnv ()
	
	id = this.ID;
	this.Insert ( "Worker", "Worker " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Material", "Material " + id );
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
	
	#region CreateCustomer
	
	p = Call ( "Catalogs.Customers.Create.Params" );
	p.Name = this.Customer;
	Call ( "Catalogs.Customers.Create", p );

	#endregion

	#region CreateVendor
	
	p = Call ( "Catalogs.Vendors.Create.Params" );
	p.Name = this.Vendor;
	Call ( "Catalogs.Vendors.Create", p );

	#endregion

	#region CreateWorker
	
	p = Call ( "Catalogs.Users.Create.Params" );
	p.Name = this.Worker;
	p.Organizations.Add ( this.Customer );
	p.Rights.Add ( "Customers / Invoices, Edit" );
	p.Rights.Add ( "Customers / Payment, Edit" );
	p.Rights.Add ( "Timesheets / Timesheets, Edit" );
	p.Rights.Add ( "Sections / Time Subsystem" );
	p.Rights.Add ( "Sections / Sales Subsystem" );
	Call ( "Catalogs.Users.Create", p );

	#endregion

	#region CreateItems
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Material;
	p.Service = false;
	Call ( "Catalogs.Items.Create", p );
	
	#endregion
	
	#region CreateVendorInvoice

	p = Call ( "Documents.VendorInvoice.Create.Params" );
	p.Date = CurrentDate () - 86400;
	p.Vendor = this.Vendor;
	p.Warehouse = "Main";
	items = new Array ();
	item = Call ( "Documents.VendorInvoice.Create.ItemsRow" );
	item.Item = this.Material;
	item.Quantity = 15;
	item.Price = 350;
	items.Add ( item );
	p.Items = items;
	Call ( "Documents.VendorInvoice.Create", p );
	With();
	Click("#FormPostAndClose");

	#endregion

	#region CreateTask
	
	Commando("e1cib/command/Catalog.Tasks.Create");
	Set ( "#Description", this.Task );
	Set ( "#Item", this.Item );
	Click("#FormWriteAndClose");

	#endregion
	
	#region CreateProject
	
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
	
	#endregion
	
	RegisterEnvironment ( id );
	
EndProcedure
