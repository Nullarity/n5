Connect ();
CloseAll ();

vendor = "_PO Services without Quantity#";
service = "_Service Test PO#";

createVendor ( vendor );
createService ( service );
poNumber = createPO ( vendor, service );
form = CurrentSource;
createVendorInvoice ( 30 );
Close ();
openReport ( poNumber );
Run ( "ReportAfterFirstVendorInvoice" );
Close ();
With ( form );
createVendorInvoice ( 70 );
Close ();
openReport ( poNumber );
Run ( "ReportAfterSecondVendorInvoice" );

// ***********************************
// Procedures
// ***********************************

Procedure createVendor ( Name )
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Organizations;
	p.Description = Name;
	p.CreateScenario = "Catalogs.Organizations.CreateVendor";
	p.CreationParams = Name;
	Call ( "Common.CreateIfNew", p );
	
EndProcedure

Procedure createService ( Name )
	
	creation = Call ( "Catalogs.Items.Create.Params" );
	creation.Description = Name;
	creation.Service = true;
	
	p = Call ( "Common.CreateIfNew.Params" );
	p.Object = Meta.Catalogs.Items;
	p.Description = Name;
	p.CreateScenario = "Catalogs.Items.Create";
	p.CreationParams = creation;
	Call ( "Common.CreateIfNew", p );
	
EndProcedure

Function createPO ( Vendor, Service )

	Call ( "Common.OpenList", Meta.Documents.PurchaseOrder );
	Click ( "#FormCreate" );
	With ( "Purchase Order (create)" );
	Set ( "#Vendor", Vendor );
	table = Activate ( "#Services" );
	Click ( "#ServicesAdd" );
	Set ( "#ServicesItem", Service, table );
	Set ( "#ServicesPrice", 100, table );
	table.EndEditRow ();
	Set ( "#ServicesAmount", 100, table );
	Clear ( "#Payments / Payment Date [ 1 ]" );
	Click ( "#FormPost" );
	po = Fetch ( "#Number" );
	return po;

EndFunction

Procedure createVendorInvoice ( Amount )

	Click ( "#FormDocumentVendorInvoiceCreateBasedOn" );
	With ( "Vendor Invoice (cr*" );
	table = Activate ( "#Services" );
	Set ( "#ServicesPrice", Amount, table );
	Set ( "#ServicesAccount", "8111", table );
	Set ( "#ServicesExpense", "Others", table );
	Click ( "#FormPost" );

EndProcedure

Procedure openReport ( poNumber )

	p = Call ( "Common.Report.Params" );
	p.Path = "Purchases / Purchase Orders by Items";
	p.Title = "Purchase Orders by Items";
	filters = new Array ();

	item = Call ( "Common.Report.Filter" );
	item.Name = "Purchase Order";
	item.Value = poNumber;
	item.UserFilter = false;
	filters.Add ( item );

	p.Filters = filters;
	With ( Call ( "Common.Report", p ) );

EndProcedure