// Check restriction of issuing invoices for government

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0FS" ) );
getEnv ();
createEnv ();

#region newInvoice
Commando("e1cib/command/Document.Invoice.Create");
Set ("#Customer", this.Customer);
Click("#JustSave");
#endregion

#region generateTaxInvoice
IgnoreErrors = true;
Click("#NewInvoiceRecord");
if ( not Waiting ( "1?:*" ) ) then
	Stop ("An error message <A tax invoice cannot be issued for a government entity> should appear");
endif;
With ();
Close ();
IgnoreErrors = false;
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
