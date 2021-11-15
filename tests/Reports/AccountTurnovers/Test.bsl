Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Turnovers" );
With ( "Account Turnovers*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

GotoRow ( "#UserSettings", "Setting", "Account" );
Put ( "#UserSettingsValue", "8111", settings );

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
