// Write off customer's debt

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A10J" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustDebts
Call ( "Documents.AdjustDebts.ListByMemo", id );
With ();
if ( Call ( "Table.Count", Get ( "#List" ) ) ) then
	Click ( "#FormChange" );
	With ();
else
	Commando ( "e1cib/command/Document.AdjustDebts.Create" );
	Set ( "#Customer", this.Customer );
	Pick ( "#Option", "Custom Account (Dr)" );
	Set ( "#Account", "7111" );
	Set ( "#Amount", 100 );
	Put ( "#Memo", id );
endif;
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );
	this.Insert ( "Date", CurrentDate () - 86400 );

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
	Pick ( "#VATUse", "Not Applicable" );
	Put("#Memo", id);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 300, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
