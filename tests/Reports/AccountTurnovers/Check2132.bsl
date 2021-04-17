Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Turnovers" );
With ( "Account Turnovers*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

// Set 2132
GotoRow ( "#UserSettings", "Setting", "Account" );
Set ( "#UserSettingsValue", "2132", settings );
Click ( "#GenerateReport" );



