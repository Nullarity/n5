// Will test credit-limit for new and saved Sales Order

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0RG" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region testZeroLimit
Commando("e1cib/command/Document.SalesOrder.Create");
Put("#Customer", this.Customer);
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000,000.00 MDL" );
CloseAll ();
#endregion

#region setLimit
Commando("e1cib/list/Document.CreditLimit");
Click("#FormCreate");
With ();
Put ("#Amount", 1000);
Put ("#Customer", this.Customer);
Click("#FormWriteAndClose");
With();
Close ();
#endregion

#region testLimitStayingAfterVariousChanges
Commando("e1cib/command/Document.SalesOrder.Create");
Put("#Customer", this.Customer);
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000.00 MDL" );
Pick ( "#VATUse", "Not Applicable" );
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Services.EndEditRow ();
Set ( "#ServicesItem", this.Service, Services );
Set ( "#ServicesQuantity", 1, Services );
Set ( "#ServicesPrice", 300, Services );
Click("#FormWrite");
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000.00 MDL" );
Click("#FormWrite");
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000.00 MDL" );
Set ( "#ServicesPrice", 600, Services );
Get ( "#RestrictionLabel1" ).ClickFormattedStringHyperlink ( "Update Information" );
warning = Get ( "#RestrictionLabel1" ).TitleText;
Assert ( warning ).Contains ( "limit is 1,000.00 MDL" );
CloseAll ();
#endregion

#region sellInCredit
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
Set ( "#ServicesPrice", 1000, table );
Click ( "#FormPostAndClose" );
#endregion

#region setZeroLimit
Commando("e1cib/list/Document.CreditLimit");
Click("#FormCreate");
With ();
Put ("#Amount", 0);
Put ("#Customer", this.Customer);
Click("#FormWriteAndClose");
With();
Close ();
#endregion

#region checkIfSendForApprovalGivesError
Commando("e1cib/command/Document.SalesOrder.Create");
Put("#Customer", this.Customer);
Pick ( "#VATUse", "Not Applicable" );
Services = Get ( "#Services" );
Click ( "#ServicesAdd" );
Services.EndEditRow ();
Set ( "#ServicesItem", this.Service, Services );
Set ( "#ServicesQuantity", 1, Services );
Set ( "#ServicesPrice", 300, Services );
Click("#FormWrite");
IgnoreErrors = true;
Click("#FormSendForApproval");
With();
Click ( "#Button0" ); // Confirm sending
With ();
Click ( "#OK" ); // Close error message
Call ( "Common.FillCheckError", "*limit*" );
IgnoreErrors = false;
#endregion

#region requestForSO
With ();
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Apply for authorization of the operation" );
With ();
Click ( "#Button0" ); // Yes
With ( "Permission to Operate *" );
Click ( "#FormOK" );
#endregion

#region approveRequest
With ();
Get ( "#RestrictionLabel1").ClickFormattedStringHyperlink ( "Request sent, await resolution" );
With ( "Permission to Operate *" );
Set ( "#Resolution", "Allow" );
Click ( "#FormOK" );
#endregion

#region sendForApprovalAgain
With ();
Click("#FormSendForApproval");
With();
Click ( "#Button0" ); // Confirm sending
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
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	#region createService
	p = Call("Catalogs.Items.Create.Params");
	p.Description = this.Service;
	p.Service = true;
	Call("Catalogs.Items.Create", p);
	#endregion

	RegisterEnvironment ( id );

EndProcedure
