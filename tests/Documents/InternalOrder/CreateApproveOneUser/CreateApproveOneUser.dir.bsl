// Creates IO and approves it.
// Returns IO document number

MainWindow.ExecuteCommand ( "e1cib/data/Document.InternalOrder" );

form = With ( "Internal Order (create)" );
Set ( "#Date", _.Date ); // It is important to be first
Set ( "#Department", _.Department );

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

responsible = _.Responsible;
Choose ( "#Responsible" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Employees;
p.Search = responsible;
Call ( "Common.Select", p );

With ( form );
//Set ( "#Responsible", responsible );
form.GotoNextItem ();

taxCode = _.TaxCode;
if ( taxCode <> undefined ) then
	Set ( "#TaxCode", taxCode );
	form.GotoNextItem ();
endif;

taxGroup = _.TaxGroup;
if ( taxGroup <> undefined ) then
	Set ( "#TaxGroup", taxGroup );
	form.GotoNextItem ();
endif;

table = Activate ( "#ItemsTable" );

for each row in _.Items do
	Click ( "#ItemsTableAdd" );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	Set ( "#ItemsPrice", row.Price, table );
	table.EndEditRow ();
	table.ChangeRow ();
	Pick ( "#ItemsReservation", row.Reservation, table );
enddo;

Activate ( "#GroupServices" );
table = Activate ( "#Services" );

for each row in _.Services do
	Click ( "#ServicesAdd" );
	table.EndEditRow ();
	
	Set ( "#ServicesItem", row.Item, table );
	Set ( "#ServicesQuantity", row.Quantity, table );
	Set ( "#ServicesPrice", row.Price, table );
	Set ( "#ServicesPerformer", row.Performer, table );
enddo;

Activate ( "More" );

if ( Get ( "#Rate" ).CurrentEnable () ) then
	Set ( "#Rate", _.Rate );
	Set ( "#Factor", _.Factor );
endif;

Click ( "#FormWrite" );
id = Fetch ( "More / #Number" );
IOTitle = "*" + id + "*";

Click ( "#FormSendForApproval" );
With ();
Click ( "Yes" );

// ***********************************
// Open list and approve IO
// ***********************************

internalOrders = Call ( "Common.OpenList", Meta.Documents.InternalOrder );

Clear ( "#StatusFilter" );
Clear ( "#ItemFilter" );
Clear ( "#WarehouseFilter" );
Clear ( "#DepartmentFilter" );

p = Call ( "Common.Find.Params" );
p.Where = "Number";
p.What = id;
Call ( "Common.Find", p );

Click ( "#FormChange" );
With ( IOTitle );
Click ( "#FormCompleteApproval" );

With ();
Click ( "Yes" );

With ( internalOrders );
Click ( "#FormChange" );

Close ( IOTitle );
Close ( internalOrders );
return id;
