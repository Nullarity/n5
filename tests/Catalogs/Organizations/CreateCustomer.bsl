// Description:
// Creates a new Customer
//
// Conditions:
// For state California tax group should be installed
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand("e1cib/data/Catalog.Organizations");
form = With("Organizations (create)");

if (_ = undefined) then
	name = "_Customer: " + CurrentDate();
	currency = __.LocalCurrency;
	terms = undefined;
	taxGroup = undefined;
	closeAdvances = true;
	clearTerms = false;
	delivery = 0;
	items = new Array();
else
	name = _.Description;
	currency = _.Currency;
	terms = _.Terms;
	taxGroup = _.TaxGroup;
	closeAdvances = _.CloseAdvances;
	clearTerms = ?(_.Property("ClearTerms"), _.ClearTerms, false);
	delivery = _.Delivery;
	items = _.Items;
endif;
//
// Fill general
//
Set("Name", name);

if (Fetch("#Customer") = "No") then
	Click("#Customer");
endif;
Click("#FormWrite");

//
// Setup Contract
//

With ( "Customer*" );
if ( AppName = "c5" ) then
	Get ( "#CustomerPage" ).Expand ();
endif;
Activate("#CustomerPage");
Get ( "#CustomerContract" ).Open ();
With("*(Contracts)");
Set("#Currency", currency);
CurrentSource.GotoNextItem();
if (terms <> undefined) then
	Set("#CustomerTerms", terms);
endif;
if (clearTerms) then
	Clear("#CustomerTerms");
endif;
Set("#CustomerDelivery", delivery);

if (closeAdvances) then
	if (Fetch("#CustomerAdvances") = "No") then
		Click("#CustomerAdvances");
	endif;
else
	if (Fetch("#CustomerAdvances") = "Yes") then
		Click("#CustomerAdvances");
	endif;
endif;

// Add items
table = Get("#Items");
for each item in _.Items do
	Click("#ItemsAdd");
	Put("#ItemsItem", item.Item);
	feature = item.feature;
	if (feature <> undefined) then
		Put("#ItemsFeature", feature);
	endif;
	package = item.Package;
	if (package <> undefined) then
		Put("#ItemsPackage", package);
	endif;
	Set("#ItemsPrice", item.Price);
enddo;

// Add services
table = Get("#Services");
for each item in _.Services do
	Click("#ServicesAdd");
	Put("#ServicesItem", item.Item);
	feature = item.feature;
	if (feature <> undefined) then
		Put("#ServicesFeature", feature);
	endif;
	Set("#ServicesPrice", item.Price);
enddo;

Click("#FormWriteAndClose");
With(form);
//
// Fill address
//
Choose("Payment address");
addresses = With("Addresses");
addressesCommands = addresses.GetCommandBar();
Click("Create", addressesCommands);
With("Addresses (create)*");
Click("#Manual");
Put("#Address", "3095 Flowers Street, Thousand Oaks, California, United States, 54321");
Click("Save and close");

With(addresses);
Click("Select", addressesCommands);

With(form);
Set("#VATUse", "Included in Price");
Click("#FormWrite");
code = Fetch("#Code");
Close();
return new Structure("Code, Description", code, name);
