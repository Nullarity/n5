return;
// To see how the report is generated in case of canceled Tax Invoice

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A17U" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region checkReport
p = Call ( "Common.Report.Params" );
p.Path = "e1cib/app/Report.Reconciliation";
p.Title = "Reconciliation Stat*";
filters = new Array ();

item = Call ( "Common.Report.Filter" );
item.Period = true;
item.Name = "Period";
item.ValueFrom = BegOfYear ( CurrentDate () );
item.ValueTo = EndOfYear ( CurrentDate () );
filters.Add ( item );

item = Call ( "Common.Report.Filter" );
item.Name = "Organization";
item.Value = this.Customer;
filters.Add ( item );

p.Filters = filters;

With ( Call ( "Common.Report", p ) );
Click ( "#GenerateReport" );
//CheckTemplate ( "#Result" );
#endregion
// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Date", CurrentDate () );

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
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region invoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date);
	Put("#Customer", this.Customer);
	Put("#Memo", id);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 300, table );
	Click ( "#FormPost" );
	Click ( "#NewInvoiceRecord" );
	With ();
	Pick ( "#Status", "Canceled" );
	Set ( "#Number", id );
	Click ( "#FormWrite" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
