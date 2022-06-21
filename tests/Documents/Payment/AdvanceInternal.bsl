// Invoice 100$ rate 20, Payment 2000 lei rate 19.
// We should'n see any advances in the accouting

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0S2" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region invoice
Call ( "Documents.Invoice.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
else
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Date);
	Put("#Customer", this.Customer);
	Pick ( "#VATUse", "Not Applicable" );
	Put("#Memo", id);
	Put("#Rate", 20);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 100, table );
	Click ( "#FormPost" );
endif;
#endregion

#region Payment
Click("#CreatePayment");
With ( "Customer Payment (create)" );
Set ( "#Amount", 2000 );
Put ( "#Currency1", "MDL" );
Activate ( "#GroupCurrency" ); // Currency
Set ( "#ContractRate", 19 );
Next ();
Activate ( "#GroupDocuments" ); // Documents
Set ( "#Amount", 2000 );
Next ();
Click ( "#FormPost" );
#endregion

#region checkRecords
Click ("#FormReportRecordsShow");
With ();
CheckTemplate ( "#TabDoc" );
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.MonthlyAdvances = true;
	p.Currency = "USD";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region newItems
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
    p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
