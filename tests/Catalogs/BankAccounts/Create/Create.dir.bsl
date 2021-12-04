// Description:
// Creates a new Bank Account
//
// Returns:
// 1) If parameters are structure then Code of created item
// 2) If parameters are string then Structure ( "Code, Description" )

if ( TypeOf ( _ ) = Type ( "String" ) ) then
	bankList = With ( "Bank Accounts" );
	Click ( "#FormCreate", bankList.GetCommandBar () );

	bankForm = With ( "Bank Accounts (Create)" );
	name = ? ( _ = undefined, "_Account " + CurrentDate (), _ );
	Set ( "#Description", name );
	Set ( "#AccountNumber", "222222" );
	mainCurrency = Call ( "Select.MainCurrencyName" );
	Set ( "#Currency", mainCurrency );
	//Choose ( "#Currency" );
	//Call ( "Select.Currency", Call ( "Select.MainCurrencyName" ) );
	Click ( "#FormWrite", bankForm.GetCommandBar () );
	With ( "*(Bank Accounts)" );
	code = Fetch ( "#Code" );
	Close ();

	return new Structure ( "Code, Description", code, name );
else
	fromOwner = true;
	if ( _.Company <> undefined ) then
		Commando("e1cib/list/Catalog.Companies");
		list = With ( "Companies" );
		GotoRow ( "#List", "Description", _.Company );
		Click ( "#FormChange" );
		form = With ( _.Company + " *" );
		fromOwner = false;
	elsif ( _.Organization <> undefined ) then
		OpenMenu ( "Catalogs / Organizations" );
		list = With ( "Organizations" );
		GotoRow ( "#List", "Name", _.Organization );
		Click ( "#FormChange" );
		form = With ( _.Organization + " *" );
		fromOwner = false;
	endif;

	if ( not fromOwner ) then
		Click ( "Bank Accounts", GetLinks () );
	endif;
	
	With ( "Bank Accounts" );

	Click ( "#FormCreate" );
	With ( "Bank Accounts (cre*" );

	if ( _.Bank <> undefined ) then
		Set ( "#Bank", _.Bank );
	endif;
	if ( _.AccountNumber <> undefined ) then
		Set ( "#AccountNumber", _.AccountNumber );
	endif;
	if ( _.Description <> undefined ) then
		Set ( "#Description", _.Description );
	endif;
	if ( _.Account <> undefined ) then
		Set ( "#Account", _.Account );
	endif;
	if ( _.Currency <> undefined ) then
		Set ( "#Currency", _.Currency );
	endif;
	if ( _.Taxes  ) then
		Click ( "#Taxes" );
	endif;
	if ( _.AccountTax <> undefined ) then
		Set ( "#AccountTax", _.AccountTax );
		Next ();
	endif;
	if ( _.Dim1 <> undefined ) then
		Set ( "#Dim1", _.Dim1 );
	endif;
	if ( _.Dim2 <> undefined ) then
		Set ( "#Dim2", _.Dim2 );
	endif;
	if ( _.Dim3 <> undefined ) then
		Set ( "#Dim3", _.Dim3 );
	endif;

	Click ( "#FormWrite" );
	code = Fetch ( "#Code" );

	Close ();
	if ( not fromOwner ) then
		With ();
		Close ();
	endif;	

	return code;
endif;