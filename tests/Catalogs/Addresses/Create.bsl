// Description:
// Creates a new CashFlow
//
// Returns:
// Structure ( "Code, Description" )

addresses = With ( "Addresses" );
commands = addresses.GetCommandBar ();
Click ( "Create", commands );
With ( "Addresses (create)" );
name = ? ( _ = undefined, "_Street: " + CurrentDate (), _ );
Put ( "Country", "United States" );
if ( not Call ( "Common.AppIsCont" ) ) then
	Set ( "#State", "California" );
endif;
Set ( "City", "Thousand Oaks" );
Set ( "Street", name );
Set ( "#ZIPFormat", "12345 (US)" );
Set ( "#ZIP", "54321" );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

Close ();

return new Structure ( "Code, Description", code, name );
