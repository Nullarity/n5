Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Turnovers" );
With ( "Account Turnovers*" );

settings = Get ( "#UserSettings" );

if ( not settings.CurrentVisible () ) then
	Click ( "#CmdOpenSettings" );
endif;

settings.Choose ();
GotoRow ( "#UserSettings", "Setting", "Account" );
Set ( "#UserSettingsValue", "2132", settings );

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

GotoRow ( "#UserSettings", "Setting", "Account" );
With ( "Account Turnovers, 2132, * quarter of *" );
settings = Get ( "#UserSettings" );
settings.Choose ();
Choose ( "#UserSettingsValue", settings );

With ( "Chart of Accounts" );
List = Get ( "#List" );
search = new Map ();
search [ "Code" ] = "2132";
search [ "Currency" ] = "No";
search [ "Description" ] = "Obiecte de mică valoare şi scurtă durată în exploatare";
search [ "Dimension 1" ] = "Items";
search [ "Dimension 2" ] = "Departments";
search [ "Dimension 3" ] = "Employees";
List.GotoRow ( search );
List.Choose ();
