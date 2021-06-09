With ( "*(Organizations)" );
Click ( "#VendorPage" );
Choose ( "#VendorContract" );
formContracts = With ( "Contracts" );
list = Activate ( "#List" );
search = new Map ();
search.Insert ( "Description", "General" );
list.GotoRow ( search, RowGotoDirection.Down );
Click ( "Edit", formContracts.GetCommandBar () );
useParams = ( _ <> undefined );
mainCurrency = ? ( useParams, _.Currency, "MDL" );
itemContractForm = With ();
Set ( "!Currency", mainCurrency );
Next();
if ( _.RateType <> undefined ) then
	Put("#VendorRateType", _.RateType);
endif;
if ( _.Rate <> undefined ) then
	Set("#VendorRate", _.Rate);
endif;
if ( useParams ) then
	if ( AppName <> "MobileVTree" ) then
		Choose ( "#VendorBank" );
		p = Call ( "Catalogs.BankAccounts.Create.Params" );
		p.Description = _.Currency;
		p.AccountNumber = "222222";
		p.Currency = _.Currency;
		Call ( "Catalogs.BankAccounts.Create", p );
		With ( "Bank Acc*" );
		Click ("#FormChoose");
		With ( itemContractForm );
		Set ("#VendorDelivery", _.Delivery);
		
		flag = ? ( _.CloseAdvances, "Yes", "No" );
		if ( flag <> Fetch ( "#VendorAdvances" ) ) then
			Click ( "#VendorAdvances" );
		endif;
	endif;
	
	// Add items
	table = Get ( "#VendorPrices" );
	for each item in _.Items do
		Click ( "#VendorItemsAdd" );
		Put ( "#VendorItemsItem", item.Item );
		feature = item.feature;
		if ( feature <> undefined ) then
			Put ( "#VendorItemsFeature", feature );
		endif;
		package = item.Package;
		if ( package <> undefined ) then
			Put ( "#VendorItemsPackage", package );
		endif;
		Set ( "#VendorItemsPrice", item.Price );
	enddo;
	
	// Add services
	table = Get ( "#VendorServices" );
	for each item in _.Services do
		Click ( "#VendorServicesAdd" );
		Put ( "#VendorServicesItem", item.Item );
		feature = item.feature;
		if ( feature <> undefined ) then
			Put ( "#VendorServicesFeature", feature );
		endif;
		Set ( "#VendorServicesPrice", item.Price );
	enddo;
else
	Choose ( "#VendorBank" );
    Call ( "Select.BankAccount", mainCurrency);
endif;	
With ( itemContractForm );
if ( ? ( useParams, _.ClearTerms, false ) ) then
	Clear ( "#VendorTerms" );
endif;
terms = ? ( useParams, _.Terms, undefined );
if ( terms <> undefined ) then
	Set ( "#VendorTerms", terms );
	Next ();
endif;
Click ( "#FormWriteAndClose", itemContractForm.GetCommandBar () );
With ( "Contracts" );
Close ();
