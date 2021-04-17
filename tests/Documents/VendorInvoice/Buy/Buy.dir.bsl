MainWindow.ExecuteCommand ( "e1cib/data/Document.VendorInvoice" );

form = With ( "Vendor Invoice (create)" );
if ( _.DateBeforeVendor ) then
	Set ( "Date", _.Date ); // It is important to be first
endif;
Choose ( "#Vendor" );
p = Call ( "Common.Select.Params" );
//for each item in Meta.Catalogs do
//	Message ( item.Key );
//enddo;
//stop ();
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
//vendorData = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
//vendorData.Description = _.Vendor;
//vendorData.Currency = _.ContractCurrency;
//p.CreationParams = vendorData;
p.Search = _.Vendor;

Call ( "Common.Select", p );

if ( not _.DateBeforeVendor ) then
	Set ( "Date", _.Date );
endif;

With ( form );
if ( _.Import ) then
	Click ( "#Import" );
endif;	
Choose ( "#Warehouse" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = _.Warehouse;
Call ( "Common.Select", p );

With ( form );
Set ( "#Warehouse", _.Warehouse );
Put ( "#Memo", _.ID );
if ( _.Property ( "IDMemo" ) ) then
	Put ( "#Memo", _.IDMemo );
endif;
form.GotoNextItem ();

table = Get ( "#ItemsTable" );
//Click ( "#ItemsTableContextMenuDelete" );
//Click ( "#ItemsTableDelete" );
for each row in _.Items do
	
	Click ( "#ItemsTableAdd" );
	
	Choose ( "#ItemsItem" );
	name = row.Item;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Items;
	params.Search = name;
	creation = Call ( "Catalogs.Items.Create.Params" );
	creation.Description = name;
	creation.CountPackages = row.CountPackages;
	creation.CostMethod = row.CostMethod;
	params.CreationParams = creation;
	Call ( "Common.Select", params );
	
	With ( form );
	
	Set ( "#ItemsItem", row.Item, table );
	Set ( "#ItemsQuantity", row.Quantity, table );
	Set ( "#ItemsPrice", row.Price, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ItemsAccount", account, table );
	endif;
enddo;

Activate ( "#GroupServices" );
table = Activate ( "#Services" );
//Click ( "#ServicesContextMenuDelete" );
//Click ( "#ServicesDelete" );
for each row in _.Services do
	Click ( "#ServicesAdd" );
	
	Choose ( "#ServicesItem" );
	name = row.Item;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Items;
	params.Search = name;
	params.Header = "Services";
	creation = Call ( "Catalogs.Items.Create.Params" );
	creation.Description = name;
	creation.Service = true;
	params.CreationParams = creation;
	Call ( "Common.Select", params );
	
	With ( form );

	Set ( "#ServicesItem", row.Item, table );
	Set ( "#ServicesQuantity", row.Quantity, table );
	Set ( "#ServicesPrice", row.Price, table );
	
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ServicesAccount", account, table );
	endif;
	
	Choose ( "#ServicesExpense" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Expenses;
	p.Search = _.Expenses;
	Call ( "Common.Select", p );
	
	With ( form );

	if ( _.ServicesIntoItems ) then
		Click ( "#ServicesIntoItems" );
		intoDocument = _.ServicesIntoDocument;
		if ( intoDocument <> Undefined ) then
			Set ( "#ServicesIntoDocument", intoDocument );
		endif;
	endif;
enddo;
Activate ( "#GroupServices" );

Click ( "#FormPost" );

Activate ( "#GroupAdditional" );
number = Fetch ( "Number" );
date = Fetch ( "Date" );

return new Structure ( "Number, Date", number, date );

