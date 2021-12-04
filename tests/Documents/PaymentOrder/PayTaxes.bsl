// Create Payment Order for taxes

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0GE" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region newPaymentOrder
Commando("e1cib/command/Document.PaymentOrder.Create");
Set("#Recipient", this.TaxAgency);
Set("#RecipientBankAccount", id);
Next ();
#endregion

#region checkAutofilling
Check("#Taxes", "Yes");
Check("#Account", "5348");
Check("#Dim1", "Дорожный сбор");
#endregion

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "TaxAgency", "TaxAgency " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createTaxAgency
	p = Call ( "Catalogs.Organizations.CreateVendor.Params" );
	p.Description = this.TaxAgency;
	Call ( "Catalogs.Organizations.CreateVendor", p );
	#endregion

	#region newBankAccount
	p = Call ("Catalogs.BankAccounts.Create.Params");
	p.Insert ( "Organization", this.TaxAgency );
	p.Insert ( "Bank" );
	p.Insert ( "AccountNumber", id );
	p.Insert ( "Taxes", true );
	p.Insert ( "AccountTax", "5348" );
	p.Insert ( "Dim1", "Дорожный сбор" );
	Call ("Catalogs.BankAccounts.Create", p);
	#endregion

	RegisterEnvironment ( id );

EndProcedure
