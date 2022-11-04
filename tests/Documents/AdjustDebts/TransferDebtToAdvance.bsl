// Will accept advance from Customer1 then will sell services to Customer2 and then will close debts

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A10X" );
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
	Set ( "#Customer", this.Customer1 );
	Pick ( "#Option", "Customer" );
	Pick ( "#Type", "Advance" );
	Put ( "#Currency", "mdl" );
	Set ( "#ContractRate", 20 );
	Set ( "#Amount", 2000 );
	Set ( "#Receiver", this.Customer2 );
	Put ( "#ReceiverAccount", "2212" );
	Put ( "#ReceiverContractRate", 21.1879 );
	Put ( "#Memo", id );
endif;

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Yesterday", CurrentDate () - 86400 );
	this.Insert ( "Customer1", "Customer1 " + id );
	this.Insert ( "Customer2", "Customer2 " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomers
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer1;
	p.Currency = "usd";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	p.Description = this.Customer2;
	p.Currency = "eur";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region acceptPayment
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Date", this.Yesterday );
	Put ( "#Customer", this.Customer1 );
	Put ( "#CustomerAccount", "2212" );
	Set ( "#ContractRate", 20 );
	Set ( "#Amount", 2000 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion
	
	#region sellServices
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.Yesterday);
	Put("#Customer", this.Customer2);
	Put ( "#CustomerAccount", "2212" );
	Put("#Memo", id);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 100, table );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
