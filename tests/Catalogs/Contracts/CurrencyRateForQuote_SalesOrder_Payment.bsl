// Create USD contract with fixed currency and then Quote / SO / Payment
// Will check currency rate over there

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A11S" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newQuote
Commando("e1cib/command/Document.Quote.Create");
Put("#Customer", this.Customer);
Put("#DueDate", Format(CurrentDate()+86400, "DLF=D"));
Put("#Currency", "MDL");
Activate("#Services");
Click("#ServicesAdd");
Put("#Services / #ServicesItem [1]", this.Service);
Put("#Services / #ServicesQuantity [1]", 1);
Put("#Services / #ServicesAmount [1]", 100);
Click("#FormPost");
#endregion

#region newSO
Click("#FormDocumentSalesOrderCreateBasedOn");
With();
Check("#Rate", 15);
Set("#Memo", id);
Click("#FormSendForApproval");
With();
Click ( "!Button0" );
#endregion

#region approveSO
Call("Documents.SalesOrder.ListByMemo", id);
With();
Click("#FormChange");
With();
Click ( "!FormCompleteApproval" );
With ();
Click ( "!Button0" );
#endregion

#region paySO
With ();
Click ( "#FormDocumentPaymentCreateBasedOn" );
With ();
Assert("#ContractRate").NotEqual (15);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Vendor", "Vendor " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	Call ( "Catalogs.Items.Create", p );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createCustomer
	p = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
	p.Description = this.Customer;
	p.Currency = "USD";
	p.RateType = "Fixed";
	p.Rate = 15;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
