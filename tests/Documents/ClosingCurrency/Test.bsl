// Closing of currency exchange differences

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A19A" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region closeCurrency
Commando ( "e1cib/command/Document.CloseCurrency.Create" );
Click ( "#Fill" );
With ( "Setup Filters" );
settings = Get ( "#UserSettings" );
Set ( "#UserSettingsValue", this.Customer, settings );
Click ( "#FormFill" );
Pause ( 2 * __.Performance );
#endregion

#region check
With ();
List = Get ( "#List" );
search = new Map ();
search [ "Amount" ] = "300.00";
if ( not List.GotoRow ( search ) ) then
	stop ( "The debt of 300.00 AED should be moved to local contract" );
endif;
search [ "Amount" ] = "-1,500.00";
if ( not List.GotoRow ( search ) ) then
	stop ( "The currency difference should be moved to local contract" );
endif;
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	date = CurrentDate ();
	this.Insert ( "Date", date );
	this.Insert ( "Currency", "AED" );
	this.Insert ( "InvoiceDate", Date ( Year ( date ) - 1, 12, 1 ) );
	this.Insert ( "Customer", "Customer " + id );
	this.Insert ( "Service", "Service " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region createCurrency
	Commando ( "e1cib/list/Catalog.Currencies" );
	search = new Map ();
	search [ "Code" ] = this.Currency;
	List = Get ( "#List" );
	if ( not List.GotoRow ( search ) ) then
		Click ( "#FormCreate" );
		//Close ( "Classifier" );
		With ();
		List = Get ( "#List" );
		search = new Map ();
		search [ "Code" ] = this.Currency;
		List.GotoRow ( search );
		List.Choose ();
		With ();
		Click ( "#FormChange" );
		With ();
		Click ( "Exchange Rates", GetLinks () );
		
		With ( "Exchange Rates" );
		Click ( "#FormCreate" );
		
		With ( "Exchange Rates (create)" );
		Set ( "#Period", " 1/01/2000" );
		Set ( "#Rate", 10 );
		Click ( "#FormWriteAndClose" );
		
		With ( "Exchange Rates" );
		Click ( "#FormCreate" );
		
		With ( "Exchange Rates (create)" );
		Set ( "#Period", Format ( EndOfMonth ( this.InvoiceDate ), "DLF=D" ) );
		Next ();
		Set ( "#Rate", 15 );
		Click ( "#FormWriteAndClose" );
	endif;
	#endregion

	#region createCustomer
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Get ( "#Customer" ).SetCheck ();
	Set ( "#CodeFiscal", id );
	Set ( "#Description", this.Customer );
	Pick ( "#VATUse", "Included in Price" );
	Click ( "#FormWrite" );
	Click ( "Contracts", GetLinks () );

	With ( "Contracts" );
	Click ( "#ListContextMenuChange" );
	With ( "General (Contracts)" );
	Set ( "#DateStart", " 1/01/2021" );
	Choose ( "#DateEnd" );
	Set ( "#DateEnd", " 1/01/2090" );
	Click ( "#FormWriteAndClose" );

	With ( "Contracts" );
	Click ( "#FormCreate" );
	
	With ( "Contracts (create)" );
	Set ( "#Currency", this.Currency );
	Next ();
	Set ( "#DateStart", " 1/01/2021" );
	Set ( "#DateEnd", " 1/01/2090" );
	Next ();
	Click ( "#FormWrite" );
	#endregion
	#region creditLimit
	Commando("e1cib/list/Document.CreditLimit");
	Click("#FormCreate");
	With ();
	Set ("#Amount", 99999);
	Put ("#Customer", this.Customer);
	Click("#FormWriteAndClose");
	#endregion
	#region createService
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = this.Service;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	#endregion
	#region createInvoice
	Commando("e1cib/command/Document.Invoice.Create");
	Put("#Date", this.InvoiceDate);
	Put("#Customer", this.Customer);
	Set("#Contract", this.Currency);
	Put("#Memo", id);
	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	Set ( "#ServicesItem", this.Service, table );
	Set ( "#ServicesQuantity", 1, table );
	Set ( "#ServicesPrice", 300, table );
	Click ( "#FormPostAndClose" );
	#endregion
		
	RegisterEnvironment ( id );

EndProcedure
