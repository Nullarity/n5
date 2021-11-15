Call ( "Common.Init" );
CloseAll ();
OpenMenu ( "Accounting / Commissionings" );
With ( "Commissionings" );
Click ( "#FormCreate" );
With ( "Commissioning (create)" );
Activate ( "#Items" );
With ( "Fixed Asset" );
CheckState ( "#Starting", "Enable", false );
Click ( "#Charge" );
date = Fetch ( "#Starting" );
wrong = "2/1/0001 12:00:00 AM";
if ( date = wrong ) then
	Stop ( "Starting From field should be equal next month" );
endif;
