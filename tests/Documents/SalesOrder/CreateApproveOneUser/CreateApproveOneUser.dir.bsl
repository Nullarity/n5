// Creates SO and approves it.
// Returns SO document number

MainWindow.ExecuteCommand ( "e1cib/data/Document.SalesOrder" );

customer = _.Customer;

form = With ( "Sales Order (create)" );
Set ( "#Date", _.Date ); // It is important to be first

Choose ( "#Customer" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
customerData = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
customerData.Description = customer;
customerData.Currency = _.ContractCurrency;
customerData.TaxGroup = _.CustomerTaxGroup;
customerData.TaxGroupCreationParams = _.CustomerTaxGroupCreationParams;
customerData.Terms = _.Terms;
p.CreationParams = customerData;
p.Search = customer;
Call ( "Common.Select", p );

With ( form );

warehouse = _.Warehouse;
if ( warehouse <> undefined ) then
	Choose ( "#Warehouse" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Warehouses;
	p.Search = warehouse;
	Call ( "Common.Select", p );
	
	With ( form );
	Set ( "#Warehouse", warehouse );
	form.GotoNextItem ();
endif;

table = Activate ( "#ItemsTable" );

for each row in _.Items do
	Click ( "#ItemsTableAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	if ( row.UseQuantity ) then
		Set ( "#ItemsQuantity", row.Quantity, table );
	else
		Set ( "#ItemsQuantityPkg", row.Quantity, table );
	endif;	
	Set ( "#ItemsPrice", row.Price, table );
	table.EndEditRow ();
	table.ChangeRow ();
	Pick ( "#ItemsReservation", row.Reservation, table );
enddo;

Activate ( "#GroupServices" );
table = Activate ( "#Services" );

for each row in _.Services do
	Click ( "#ServicesAdd" );
	
	p = Call ( "Catalogs.Items.Create.Params" );
	name = row.Item;
	p.Description = name;
	p.Service = true;
	Call ( "Catalogs.Items.Create", p );
	Set ("#ServicesItem", name);
	
	// Choose ( "#ServicesItem" );
	// name = row.Item;
	// params = Call ( "Common.Select.Params" );
	// params.Object = Meta.Catalogs.Items;
	// params.Search = name;
	// creation = Call ( "Catalogs.Items.Create.Params" );
	// creation.Description = name;
	// creation.Service = true;
	// params.CreationParams = creation;
	// Call ( "Common.Select", params );
	
	// With ( form );
	
	table.EndEditRow ();
	Set ( "#ServicesItem", row.Item, table );
	Set ( "#ServicesQuantity", row.Quantity, table );
	Set ( "#ServicesPrice", row.Price, table );
	performer = row.Performer;
	if ( performer <> undefined ) then
		Set ( "#ServicesPerformer", performer, table );
	endif;
enddo;

taxGroup = _.TaxGroup;
if ( taxGroup <> undefined ) then
	Set ( "#TaxGroup", taxGroup );
endif;

Activate ( "More" );

if ( Get ( "#Rate" ).CurrentEnable () ) then
	Set ( "#Rate", _.Rate );
	Set ( "#Factor", _.Factor );
endif;

if ( _.Department <> undefined ) then
	Set ( "#Department", _.Department );
endif;

Set ( "#Memo", _.Memo );

With ( "Sales Order (create) *" );
Payments = Get ( "#Payments" );
Click ( "#PaymentsAdd" );
Put ( "#PaymentsPaymentOption", "Payments" );
Choose ( "#PaymentsPaymentDate", Payments );

Click ( "#FormWrite" );
CheckErrors ();
id = Fetch ( "More / #Number" );
salesOrdertitle = "*" + id + "*";

Click ( "#FormSendForApproval" );
With ();
Click ( "Yes" );

// ***********************************
// Open list and approve SO
// ***********************************

salesOrders = Call ( "Common.OpenList", Meta.Documents.SalesOrder );

Clear ( "#CustomerFilter" );
Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = id;
Call ( "Common.Find", p );

Click ( "#FormChange" );
With ( salesOrdertitle );
Click ( "#FormCompleteApproval" );

With ();
Click ( "Yes" );

With ( salesOrders );
Click ( "#FormChange" );

// ***********************************
// Complete Shipment
// ***********************************

if ( _.Shipments
	and _.Items.Count () > 0 ) then
	Commando ( "e1cib/list/Document.Shipment" );
	//shipments = Call ( "Common.OpenList", Meta.Documents.Shipment );
	shipments = With ();
	
	Set ( "#CustomerFilter", customer );
	Clear ( "#StatusFilter" );
	Clear ( "#ItemFilter" );
	Clear ( "#WarehouseFilter" );
	Clear ( "#DepartmentFilter" );
	
	Click ( "#FormChange" );
	form = With ( "Shipment #*" );
	Click ( "#FormStart" );
	With ( DialogsTitle );
	Click ( "Yes" );
	With ( form );
	table = Activate ( "#Items" );
	Click ( "#ItemsPicked [ 1 ]", table );
	Click ( "#ItemsPicked [ 2 ]", table );
	Click ( "#FormComplete" );
	With ( DialogsTitle );
	Click ( "Yes" );
	
	Close ( shipments );
endif;

Close ( salesOrdertitle );
Close ( salesOrders );
return id;
