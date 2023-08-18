// Will receive advance from customer and then will write off that advance

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A17P" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region adjustments
Call ( "Documents.AdjustDebts.ListByMemo", id );
try
	Click ( "#FormChange" );
	With ();
	try
		Click ( "#FormUndoPosting" );
	except
	endtry;	
except
	With ();
	Click ( "#FormCreate" );
	With ();
	Pick ( "#Option", "Custom Account (Cr)" );
	Set ( "#Customer", this.Customer );
	Set ( "#Account", "6111" );
	Set ( "#Memo", id );
	Set ( "#Amount", 100 );
endtry;
Click ( "#FormPost" );
#endregion

Click ( "#FormReportRecordsShow" );
With ();
CheckTemplate ( "#TabDoc" );

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );

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

	#region receiveAdvance
	Commando ( "e1cib/command/Document.Payment.Create" );
	Set ( "#Customer", this.Customer );
	Set ( "#Amount", 100 );
	Click ( "#FormPostAndClose" );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
