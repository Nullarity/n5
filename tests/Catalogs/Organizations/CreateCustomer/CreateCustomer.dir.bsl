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
	company = undefined;
	currency = __.LocalCurrency;
	terms = undefined;
	taxGroup = undefined;
	closeAdvances = true;
	clearTerms = false;
	delivery = 0;
	items = new Array();
	codeFiscal = undefined;
	bankAccount = undefined;
	paymentAddress = undefined;
	government = false;
	signed = false;
	contractDateStart = undefined;
	contractDateEnd = undefined;
	createCredit = false;
else
	company = _.Company;
	government = _.Government;
	name = _.Description;
	currency = _.Currency;
	terms = _.Terms;
	taxGroup = _.TaxGroup;
	closeAdvances = _.CloseAdvances;
	clearTerms = ?(_.Property("ClearTerms"), _.ClearTerms, false);
	delivery = _.Delivery;
	items = _.Items;
	codeFiscal = _.CodeFiscal;
	bankAccount = _.BankAccount;
	paymentAddress = _.PaymentAddress;
	rateType = _.RateType;
	rate = _.Rate;
	signed = _.ContractSigned;
	contractDateStart = _.ContractDateStart;
	contractDateEnd = _.ContractDateEnd;
	createCredit = _.CreateCredit;
	creditLimit = _.CreditLimit;
	contractDateEnd = _.ContractDateEnd;
endif;
//
// Fill general
//
Set("Name", name);
if (codeFiscal<> undefined) then
	Set("#CodeFiscal", codeFiscal);
endif;

if (Fetch("#Customer") = "No") then
	Click("#Customer");
endif;

if ( government ) then
	Click ( "#Government" );
endif;

Click("#FormWrite");
CheckErrors();

Get ( "#CustomerPage" ).Expand ();

if ( paymentAddress <> undefined ) then
	CheckErrors();
	field = Activate("#PaymentAddress");
	field.OpenDropList ();
	field.Create ();
	With();
	Click("#Manual");
	Set("#Address", paymentAddress);
	Click("#FormWriteAndClose");
	CheckErrors();
	With();
endif;
//
// Credit limit
//
if ( createCredit ) then
	Commando("e1cib/list/Document.CreditLimit");
	Click("#FormCreate");
	With ();
	Set ("#Amount", creditLimit);
	Put ("#Customer", name);
	if (Company<>undefined) then
		Put ( "#Company", company );
	endif;
	Put ("#Customer", name);
	Click("#FormWriteAndClose");
	With();
	Close ();
endif;
//
// Setup Contract
//
With ();
Activate("#CustomerPage");
Get ( "#CustomerContract" ).Open ();
With("*(Contracts)");
if ( company <> undefined ) then
	Put ( "#Company", _.Company );
endif;
if ( signed ) then
	Click("#Signed");
endif;
if ( contractDateStart <> undefined ) then
	Set ( "#DateStart", Format ( contractDateStart, "DLF=D" ) );
endif;
if ( contractDateEnd <> undefined ) then
	Set ( "#DateEnd", Format ( contractDateEnd, "DLF=D" ) );
endif;
Set("#Currency", currency);
CurrentSource.GotoNextItem();
if ( rateType <> undefined ) then
	Put("#CustomerRateType", rateType);
endif;
if ( rate <> undefined ) then
	Set("#CustomerRate", rate);
endif;
if (terms <> undefined) then
	Set("#CustomerTerms", terms);
endif;
if (clearTerms) then
	Clear("#CustomerTerms");
endif;
if ( bankAccount <> undefined ) then
	Activate("#CustomerBank").Create ();
	With();
	Set("#AccountNumber", bankAccount);
	Put("#Account", "2421");
	Next();
	Click("#FormWriteAndClose");
	CheckErrors();
	With();
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
