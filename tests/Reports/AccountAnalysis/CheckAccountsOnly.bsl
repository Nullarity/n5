Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Analysis" );
With ( "Account Analysis*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

GotoRow ( "#UserSettings", "Setting", "Account" );
Set ( "#UserSettingsValue", "10101", settings );

// ********************************
// Disable Dimensions & Currencies
// ********************************

GotoRow ( "#UserSettings", "Setting", "Show analytics" );
Click ( "#UserSettingsUse" );

GotoRow ( "#UserSettings", "Setting", "Show currencies" );
Click ( "#UserSettingsUse" );

Click ( "#GenerateReport" );
