// Check restriction of issuing invoices for government

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A15E" ) );
getEnv ();
createEnv ();

#region newInvoice
Commando("e1cib/command/Document.Invoice.Create");
Set ("#Customer", this.Customer);
Click("#JustSave");
#endregion

#region generateTaxInvoice
Click("#NewInvoiceRecord");
With ();
Clear ( "#Range" );
Set ( "#Number", this.ID + this.ID );
Click ("#FormPrint");
if ( FindMessages ( "*government organization*").Count () = 0 ) then
	Stop ( "Error message must be shown" );
endif;
CloseAll ();
#endregion

// *************************
// Procedures
// *************************

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
	p.Government = true;
	Call ( "Catalogs.Organizations.CreateCustomer", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
