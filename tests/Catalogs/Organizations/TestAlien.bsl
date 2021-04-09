// Open organization and try to press on Alien checkbox

Call ( "Common.Init" );
CloseAll ();

// *************************
// Open Organization
// *************************

Commando ( "e1cib/data/Catalog.Organizations" );
With ();

Click ( "#Alien" );

if ( Fetch ( "#Alien" ) <> "Yes" ) then
	Stop ( "Non-resident must be yes" );
endif;

