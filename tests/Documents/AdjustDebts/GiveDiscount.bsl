// Will give a discount to customer

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0YV" );
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
	Click ( "#ApplyVAT" );
	Click ( "#Reversal" );
	Pick ( "#Option", "Custom Account (Dr)" );
	Set ( "#Account", "6111" );
	Set ( "#Amount", 100 );
	Put ( "#Memo", id );
	Click ( "#AccountingAdd" );
	Accounting = Get ( "#Accounting" );
	Accounting.EndEditRow ();
	Set ( "#AccountingItem [ 1 ]", this.Discounts, Accounting );
	Set ( "#AccountingAmount [ 1 ]", 100, Accounting );
endif;
Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Discounts", "Discounts " + id );

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
	p.Description = this.Discounts;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
