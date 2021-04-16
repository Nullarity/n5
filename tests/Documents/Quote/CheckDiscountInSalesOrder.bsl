// Create Quote with discounts and check if is correctly migrages to SO

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CF2DA95" ) );
getEnv ();
createEnv ();

#region newQuote
Commando("e1cib/command/Document.Quote.Create");
Set ( "!Customer", this.Customer );
Set ( "!DueDate", Format ( CurrentDate() + 86400, "DLF=D" ) );
Services = Get ( "!Services" );
Click ( "!ServicesAdd" );
Services.EndEditRow ();
Set ( "!ServicesItem", this.Service, Services );
Set ( "!ServicesQuantity", 1, Services );
Set ( "!ServicesPrice", 10, Services );
Set ( "!ServicesDiscountRate", 5, Services );
discount = Number ( Fetch ("!ServicesDiscount", Services) );
amount = Number ( Fetch ("!ServicesAmount", Services) );
Click ( "!FormDocumentSalesOrderCreateBasedOn" );
With ();
Click ( "!Button0" );
#endregion

#region checkSalesOrder
With();
Services = Get ( "!Services" );
Check ("!ServicesDiscount", discount, Services);
Check ("!ServicesAmount", amount, Services);
#endregion

#region approveSO
Click ( "!FormSendForApproval" );
With ();
Click ( "!Button0" );
With ( "Quote *" );
Click ( "!Links[1]" );
With ();
Click ( "!FormCompleteApproval" );
With ();
Click ( "!Button0" );
#endregion

#region paySO
With ( "Quote *" );
Click ( "!Links[1]" );
With ( "Sales Order *" );
Click ( "!FormPayment" );
With ();
Click ( "!FormPostAndClose" );
#endregion

#region checkInvoive
With ( "Sales Order *" );
Click ( "!FormInvoice" );
With ( "Invoice *" );
Services = Get ( "!Services" );
Check ("!ServicesDiscount", discount, Services);
Check ("!ServicesAmount", amount, Services);
Check ( "!Discount", discount);
Click ( "!FormPost" );
Check ("!Discount", discount);
#endregion


// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
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

	#region createItem
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
