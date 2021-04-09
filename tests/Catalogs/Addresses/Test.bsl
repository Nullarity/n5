Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/command/Catalog.Addresses.Create" );
With ( "Addresses (cr*" );

// Test Zip Format coming from Country
Pick ( "#Country", "United States" );
Get("#Country").Open ();
With ();
Set("#ZIPFormat", "12345-1234 (US+4)");
Click("#FormWriteAndClose");
With();
Pick ( "#Country", "United States" );
Check("#ZIPFormat", "12345-1234 (US+4)");
Get("#Country").Open ();
With ();
Set("#ZIPFormat", "12345 (US)");
Click("#FormWriteAndClose");
With();

// Fill other fields
Pick ( "#Country", "United States" );
Set ( "#State", "California" );
Set ( "#Municipality", "Municipality" );
Set ( "#City", "Thousand Oaks" );
Set ( "#Street", "Street" );
Set ( "#Number", "3095" );
Set ( "#Building", "5" );
Set ( "#Entrance", "3" );
Set ( "#Floor", "9" );
Set ( "#Apartment", "765" );
Set ( "#ZIP", "12345" );
Next ();

if ( Fetch ( "#Address" ) = "" ) then
	Stop ( "Address is not filled" );
endif;