// Create Invoice and Unload it

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A03F" ) );
getEnv ();
createEnv ();

#region UnloadData

Commando("e1cib/app/DataProcessor.UnloadInvoices");
Click ( "#IncludeWaiting" );
Click ( "#MarkAll" );
path = __.Files + "efactura.xml";
Set ( "#Path", path );
Click ( "#InvoicesUnloadButton" );

#endregion

#region CheckResult

Pause ( 3 );
file = new File ( path );
Assert ( file.Exist (), path ).IsTrue ();
With ();
Close ();
Pause ( 3 );
Assert ( file.Exist (), path ).IsFalse ();

#endregion

Disconnect ();

// *************************
// Procedures
// *************************

Procedure getEnv ()
	
	id = this.ID;
	this.Insert ( "Accountant", "Accountant " + id );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region CreateCustomer
	p = Call ( "Catalogs.Customers.Create.Params" );
	p.Name = this.Customer;
	p.PaymentAddress = "Customer Payment Address 123";
	p.BankAccount = id;
	Call ( "Catalogs.Customers.Create", p );

	#endregion

	#region CreateAccountant
	
	p = Call ( "Catalogs.Users.Create.Params" );
	p.Name = this.Accountant;
	p.Organizations.Add ( this.Customer );
	p.Rights.Add ( "General / Save Settings" );
	p.Rights.Add ( "Customers / Invoices, Edit" );
	p.Rights.Add ( "Customers / Invoice Record, Edit" );
	p.Rights.Add ( "Sections / Sales Subsystem" );
	p.Rights.Add ( "Items / Items, Edit" );
	p.Rights.Add ( "Items / Ranges, Edit" );
	p.Rights.Add ( "Tools / Calendar" );
	Call ( "Catalogs.Users.Create", p );

	#endregion
	
	Call ( "Common.NewSession", this.Accountant );

	#region CreateService
		
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	#endregion
	
	#region CreateRange
	
	Commando("e1cib/command/Catalog.Ranges.Create");
	Put ( "#Type", "Invoices Online" );
	Set ( "#Length", 9 );
	Set ( "#Description", id );
	Click ( "#WriteAndClose" );
	CheckErrors ();

	Commando("e1cib/command/Document.EnrollRange.Create");
	Set ( "#Range", id );
	Click ( "#FormWriteAndClose" );
	CheckErrors ();

	#endregion
	
	#region CreateInvoice
	
	p = Call ( "Documents.Invoice.Sale.Params" );
	p.Action = "Post";
	p.Date = CurrentDate ();
	p.Customer = this.Customer;
	p.Warehouse = "Main";
	services = new Array ();
	item = Call ( "Documents.Invoice.Sale.ServicesRow" );
	item.Item = this.Service;
	item.Quantity = 1;
	item.Price = 350;
	services.Add ( item );
	p.Services = services;
	Call ( "Documents.Invoice.Sale", p );
	
	#endregion
	
	#region InvoiceRecord
	
	With ();
	Click ( "#NewInvoiceRecord" );
	
	With ();
	Choose ( "#Range" );
	With ();
	GotoRow("#List", "Range", id);
	Click ( "#FormChoose" );
	
	With();
	Click ( "#FormWriteAndClose" );
	CheckErrors ();
	
	#endregion

	Call("Common.ChangeSession");
	RegisterEnvironment ( id );
	
EndProcedure
