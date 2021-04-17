Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Balance" );
With ( "Account Balance*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

GotoRow ( "#UserSettings", "Setting", "Account" );
Set ( "#UserSettingsValue", "8111", settings );

// After that I should be able to see Expenses dimension
dimensionName = "Expenses";
GotoRow ( "#UserSettings", "Setting", dimensionName );

// Check link by type: Open list of Expenses
Choose ( "Value", settings );
With ( "Expenses" );
