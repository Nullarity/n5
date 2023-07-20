// Create Quote with discounts and check if it correctly migrages to Invoice via SO

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "2CF2961F" ) );
getEnv ();
createEnv ();

#region newQuote
Commando("e1cib/command/Document.Quote.Create");
Set ( "!Customer", this.Customer );
Set ( "!DueDate", Format ( CurrentDate() + 86400, "DLF=D" ) );
table = Get ( "!Items" );
Click ( "!ItemsAdd" );
table.EndEditRow ();
Set ( "!ItemsItem", this.Item, table );
Set ( "!ItemsQuantity", 5, table );
Set ( "!ItemsPrice", 100, table );
Services = Get ( "!Services" );
Click ( "!ServicesAdd" );
Services.EndEditRow ();
Set ( "!ServicesItem", this.Service, Services );
Set ( "!ServicesQuantity", 1, Services );
Set ( "!ServicesPrice", 10, Services );
Set ( "!ServicesDiscountRate", 5, Services );
discount = Number ( Fetch ("!ServicesDiscount", Services) );
amount = Number ( Fetch ("!ServicesAmount", Services) );
Click ( "!FormDocumentInvoiceCreateBasedOn" );
With ();
Click ( "!Button0" );
#endregion

#region checkInvoice
With();
Activate ( "!Services" );
Services = Get ( "!Services" );
Check ("!ServicesDiscount", discount, Services);
Check ("!ServicesAmount", amount, Services);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Item", "Item " + id );
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
	p.Description = this.Item;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Service = true;
	p.Description = this.Service;
	Call ( "Catalogs.Items.Create", p );
	#endregion

	RegisterEnvironment ( id );

EndProcedure
