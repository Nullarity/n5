Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Subsidiary Ledger" );
With ( "Subsidiary Ledger*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

// Set 10101
GotoRow ( "#UserSettings", "Setting", "Account" );
Put ( "#UserSettingsValue", "10101", settings );
Click ( "#GenerateReport" );
