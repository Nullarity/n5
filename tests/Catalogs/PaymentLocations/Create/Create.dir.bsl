// Description:
// Creates a new Payment Location
//
// Conditions:
// User should have default Company
//
// Returns:
// Structure ( "Code, Description" )

Commando ( "e1cib/data/Catalog.PaymentLocations" );
if ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	name = _.Description;
	value = _.Company;
	if ( value  <> undefined ) then
		Set ("#Company", value );
	endif;
	value = _.Account;
	if ( value  <> undefined ) then
		Set ("#Account", value );
	endif;
	value = _.Method;
	if ( value  <> undefined ) then
		Set ("#Method", value );
	endif;
	if ( _.Register ) then
		Click("#Register");
	endif;
	if ( _.Remote ) then
		Click("#Remote");
	endif;
else
	name = "_Location: " + CurrentDate ();
endif;
Set ( "Description", name );
Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();
return new Structure ( "Code, Description", code, name );
