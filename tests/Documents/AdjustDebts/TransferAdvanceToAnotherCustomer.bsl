// Will accept advance payment 2000 lei (with rate = 19) from Customer1
// and then transfer this advance to Customer2

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0TB" );
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
	Set ( "#ContractRate", 19 );
	Set ( "#Amount", 2100 );
	Set ( "#Receiver", this.Customer2 );
	Put ( "#Memo", id );
	Click ( "#AccountingAdd" );
	Accounting = Get ( "#Accounting" );
	Accounting.EndEditRow ();
	Set ( "#AccountingItem [ 1 ]", this.Service, Accounting );
	Set ( "#AccountingAmount [ 1 ]", 5.27, Accounting ); // 5.26 = 100 / 19
endif;
Click ( "#FormPost" );

return;


Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
Close ();
With ();
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", CurrentDate () );
	this.Insert ( "Customer1", "Customer1 " + id );
	this.Insert ( "Customer2", "Customer2 " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer1;
	p.Currency = "usd";
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	p.Description = this.Customer2;
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
	Set ( "#Date", CurrentDate () - 86400 );
	Pick ( "#Customer", this.Customer1 );
	Set ( "#ContractRate", 19 );
	Set ( "#Amount", 2000 );
	Next ();
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
