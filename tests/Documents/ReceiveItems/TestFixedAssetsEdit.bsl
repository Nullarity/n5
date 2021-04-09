Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Warehousing / Receive Items" );
With ( "Receive Items" );
Click ( "#FormCreate" );
With ( "Receive Items (create)" );
Click ( "#FixedAssetsAdd" );
With ( "Fixed Asset" );
CheckState ( "#Starting", "Enable", false );
Click ( "#Charge" );
date = Fetch ( "#Starting" );
wrong = "2/1/0001 12:00:00 AM";
if ( date = wrong ) then
	Stop ( "Starting From field should be equal next month" );
endif;
