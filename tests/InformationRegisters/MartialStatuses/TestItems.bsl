Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/InformationRegister.MaritalStatuses" );

With ( "Marital Statuses (cr*" );

CheckState ( "#Select", "Enable", false );
CheckState ( "#Spouse", "Enable", false );
CheckState ( "#Country", "Enable", false );
CheckState ( "#PIN", "Enable", false );

Put ( "#Status", "Married" );
CheckState ( "#Select", "Enable" );
CheckState ( "#Spouse", "Enable", false );
CheckState ( "#Country", "Enable" );
CheckState ( "#PIN", "Enable" );

Click ( "#Select" );
CheckState ( "#Select", "Enable" );
CheckState ( "#Spouse", "Enable" );
CheckState ( "#Country", "Enable", false );
CheckState ( "#PIN", "Enable", false );

Put ( "#Status", "Single" );
CheckState ( "#Select", "Enable", false );
CheckState ( "#Spouse", "Enable", false );
CheckState ( "#Country", "Enable", false );
CheckState ( "#PIN", "Enable", false );
