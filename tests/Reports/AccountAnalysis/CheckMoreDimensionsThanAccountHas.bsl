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

GotoRow ( "#UserSettings", "Setting", "Show analytics" );
Set ( "#UserSettingsValue", "1, 2 level", settings );

Click ( "#GenerateReport" );
