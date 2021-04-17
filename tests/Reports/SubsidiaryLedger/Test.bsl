Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Subsidiary Ledger" );
With ( "Subsidiary Ledger*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

// Generate as is
Click ( "#GenerateReport" );

// Enable currency
GotoRow ( "#UserSettings", "Setting", "Show Currencies" );
Click ( "#UserSettingsUse" );
Click ( "#GenerateReport" );

// Enable Dimension1
GotoRow ( "#UserSettings", "Setting", "Show Analytics" );
Click ( "#UserSettingsUse" );
Click ( "#GenerateReport" );
