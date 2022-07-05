// Check how VAT from advances works if advances are entered in Customer Balances

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0SE" );
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
	Put("#Memo", id);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 300, table );
endif;
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
#endregion

CheckTemplate ( "#TabDoc" );

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
	
	#region newService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region customerDebts
	OpenMenu ( "Sections panel / Accounting" );
	OpenMenu ( "Functions menu / See also / Opening Balances" );
	With ();
	confirmation = Date(Fetch ( "#BalanceDate" )) <> Date(1, 1, 1);
	Put("#BalanceDate", "1/1/2018");
	if ( confirmation ) then
		Click ( "Yes", "1?:*" );
		Next();
		Waiting ( "WaitUntilChangingProcessComplete", 5 * __.Performance );
	endif;
	Click ( "#FormCreateByParameterDebts" );
	With ();
	Put ( "#Account", "5231" );
	Next ();
	Debts = Get ( "#Debts" );
	Click ( "#DebtsAdd" );
	Debts.EndEditRow ();
	Set ( "#DebtsCustomer", this.Customer, Debts );
	Set ( "#DebtsAdvance", 100, Debts );
	Click ( "#FormPost" );
	Close ();
	#endregion
	
	#region VATfromAdvances
	With ( "Opening Balances" );
	Click ( "#FormCreateByParameterBalances" );
	With ();
	Put ( "#Account", "2252" );
	Next ();
	Details = Get ( "#Details" );
	Set ( "#DetailsDim1", this.Customer, Details );
	Set ( "#DetailsAmount", 16.67, Details );
	Click ( "#FormPost" );
	Close ();
	#endregion

	RegisterEnvironment ( id );

EndProcedure
