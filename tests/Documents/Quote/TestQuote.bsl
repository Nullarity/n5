Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2BE5ABB1" );
env = getEnv ( id );
createEnv ( env );

Commando ( "e1cib/list/Document.Quote" );
With ();
Put ( "#CustomerFilter", Env.Customer );
Click ( "#FormChange" );
With ();

Click ( "#FormDataProcessorQuoteQuote" );
With();
Call ( "Common.CheckLogic", "#TabDoc" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )

	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Item", "Service " + ID );
	p.Insert ( "Company", "Company: " + ID );
	p.Insert ( "Customer", "Customer: " + ID );
	p.Insert ( "PaymentAddress", "Payment Address test test test test test test: " + ID );
	p.Insert ( "Employee", "Employee: " + ID );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Item
	// *************************
	
	p = Call ( "Catalogs.Items.Create.Params" );
	p.Description = Env.Item;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	
	// *************************
	// Create Customer
	// *************************
	Commando ( "e1cib/data/Catalog.Organizations" );
	With ( "Organizations (create)" );
	Put ( "#Description", Env.Customer );
	Click ( "#Customer" );
	Click ( "#FormWriteAndClose" );

	// *************************
	// Create Company
	// *************************
	Call ( "Catalogs.Companies.Create", Env.Company );

	// *************************
	// Addresses
	// *************************
	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Click ( "#Manual" );
	Put ( "#Address", Env.PaymentAddress );
	setValue ( "#Owner", Env.Company, "Companies" );
	Click ( "#FormWriteAndClose" );
	
	// Complete Company
	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );

	p = Call ( "Common.Find.Params" );
	p.Where = "Description";
	p.What = Env.Company;
	Call ( "Common.Find", p );
	Pause (3);
	Click ( "#ListContextMenuChange" );
	form = With ( Env.Company + "*" );
	Put ( "#PaymentAddress", Env.PaymentAddress );
	
	path = __.Files + "logo.png";
	App.SetFileDialogResult ( true, path );
	Click ( "#UploadStamp" );
    Pause (2);
	// Set Logo, Stamp
	App.SetFileDialogResult ( true, path );
	Click ( "#Upload" );
	
	With ( form );
	
	Click ( "Contacts", GetLinks () );
	With ( "Contacts" );
	
	Click ( "#FormCreate" );
	With ();
	Put ( "#BusinessPhone", "(555) 111-5555" );
	Put ( "#Email", "email@email.com" );
	Put ( "#FirstName", "Director" );
	Put ( "#ContactType", "Director" );
	Click ( "#FormWriteAndClose" );
	
	With ( Env.Company + "*" );
	Click ( "Main", GetLinks () );
	With ( Env.Company + "*" );
	Click ( "#FormWriteAndClose" );


	// set Employee in User
	// Complete Company
	Commando ( "e1cib/list/Catalog.Users" );
	With ();
	p = Call ( "Common.Find.Params" );
	p.Where = "Name";
	p.What = "admin";
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	form = With ();
    Get ( "#Group3" ).Expand ();
    Activate ( "#Group3" ); // More
	Clear ( "#Employee" );
	Click ( "#CreateEmployee" );
	With ();

	// *************************
	// Create Individual
	// *************************
    
	Put ( "#FirstName", Env.Employee );
	// Set Signature
	App.SetFileDialogResult ( true, path );

	Click ( "#UploadSignature" );
	Click ( "#FormWriteAndClose" );

	With ( form );
	Click ( "#FormWriteAndClose" );
	Pause (4*__.Performance);
	
    // *************************
	// Create Quote
	// *************************

	Commando ( "e1cib/data/Document.Quote" );
	formMain = With ( "Quote (cr*" );
	Put ( "#Company", Env.Company );
	Put ( "#Customer", Env.Customer );
	Put ( "#VATUse", "Excluded from Price" );
	Put ( "#Guarantee", "Guarantee" + id );

	table = Get ( "#Services" );
	Click ( "#ServicesAdd" );

	Put ( "#ServicesItem", env.Item, table );
	Put ( "#ServicesQuantity", 10, table );
	Put ( "#ServicesPrice", 100, table );

	Click ( "#ServicesAdd" );

	Put ( "#ServicesItem", env.Item, table );
	Put ( "#ServicesQuantity", 5, table );
	Put ( "#ServicesPrice", 200, table );
	Next ();
	Click ( "#JustSave" );
	CheckErrors ();
	Close ();
	
	Call ( "Common.StampData", id );

EndProcedure

Procedure setValue ( Field, Value, Object, GoToRow = "Description" )

	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", Object );
	Click ( "#OK" );
	if ( Object = "Companies" ) then
		With ( "Addresses*" );
		Put ( "#Owner", Value );
	else
		With ( Object );
		GotoRow ( "#List", GoToRow, Value );
		Click ( "#FormChoose" );
		CurrentSource = form;
	endif;
	
EndProcedure
