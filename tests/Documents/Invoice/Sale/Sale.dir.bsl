MainWindow.ExecuteCommand ( "e1cib/data/Document.Invoice" );

form = With ( "Invoice (create)" );
Set ( "Date", _.Date ); // It is important to be first

Choose ( "#Customer" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
customerData = Call ( "Catalogs.Organizations.CreateCustomer.Params" );
customerData.Description = _.Customer;
customerData.Currency = _.ContractCurrency;
customerData.TaxGroup = _.CustomerTaxGroup;
customerData.TaxGroupCreationParams = _.CustomerTaxGroupCreationParams;
p.CreationParams = customerData;
p.Search = _.Customer;
Call ( "Common.Select", p );

With ( form );

warehouse = _.Warehouse;
if ( warehouse <> undefined ) then
	Choose ( "#Warehouse" );
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Warehouses;
	p.Search = _.Warehouse;
	Call ( "Common.Select", p );

	With ( form );
	Set ( "#Warehouse", _.Warehouse );
	form.GotoNextItem ();
endif;

department = _.Warehouse;
if ( department <> undefined ) then
	Set ( "#Department", _.Department );
endif;

table = Activate ( "#ItemsTable" );

for each row in _.Items do
	Click ( "#ItemsTableAdd" );
	
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

for each row in _.Services do
	Click ( "#ServicesAdd" );
	
	Choose ( "#ServicesItem" );
	name = row.Item;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.Items;
	params.Search = name;
	creation = Call ( "Catalogs.Items.Create.Params" );
	creation.Description = name;
	creation.Service = true;
	params.CreationParams = creation;
	params.Header = "Services";

	Call ( "Common.Select", params );
	
	With ( form );

	Set ( "#ServicesItem", row.Item, table );
	Set ( "#ServicesQuantity", row.Quantity, table );
	Set ( "#ServicesPrice", row.Price, table );
	account = row.Account;
	if ( account <> undefined ) then
		Set ( "#ServicesAccount", account, table );
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

action = _.Action;
if ( action = "PostAndClose" ) then
	Click ( "#FormPostAndClose" );
else
	if ( action = "Post" ) then
		Click ( "#FormPost" );
	elsif ( action = "Save" ) then
		Click ( "#FormWrite" );
	endif;
	return form;
endif;
