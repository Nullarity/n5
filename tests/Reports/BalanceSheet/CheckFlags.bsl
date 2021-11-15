Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Balance Sheet" );
With ( "Balance Sheet*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

// ****************************
// Test standard flags statuses
// ****************************

GotoRow ( settings, "Setting", "Show Accounts Hierarchy" );
Check ( "#UserSettingsValue", "Yes", settings );

GotoRow ( settings, "Setting", "Show Analytics" );
Check ( "#UserSettingsValue", "1 level", settings );

GotoRow ( settings, "Setting", "Show Analytics Hierarchically" );
Check ( "#UserSettingsValue", "No", settings );

GotoRow ( settings, "Setting", "Show Currencies" );
Check ( "#UserSettingsValue", "Yes", settings );

GotoRow ( settings, "Setting", "Show Quantity" );
Check ( "#UserSettingsValue", "Yes", settings );

// *****************************
// Change Account and test flags
// *****************************

GotoRow ( "#UserSettings", "Setting", "Account" );
Set ( "#UserSettingsValue", "8111", settings );

error = GotoRow ( settings, "Setting", "Currency" );
if ( error ) then
	Stop ( "Currency filter should be invisible" );
endif;