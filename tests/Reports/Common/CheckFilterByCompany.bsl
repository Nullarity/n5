Call ( "Common.Init" );
CloseAll ();

// Admin has access to all compaies therefore filter by default company
// should be installed
checkFilter ( __.Company );
Close ();

// Leave 1 company only by removing the second one.
// Filter by company should not be installed
changeDeletionMark ();
checkFilter ( "" );
Close ();

// Undelete company for further tests
changeDeletionMark ();

// ***********************************
// Procedures
// ***********************************

Procedure checkFilter ( Value )

	OpenMenu ( "Accounting / Balance Sheet" );
	With ( "Balance Sheet*" );

	settings = Get ( "#UserSettings" );

	if ( not settings.CurrentVisible () ) then
		Click ( "#CmdOpenSettings" );
	endif;

	GotoRow ( "#UserSettings", "Setting", "Company" );
	Check ( "#UserSettingsValue", Value, settings );
	
EndProcedure

Procedure changeDeletionMark ()

	Commando ( "e1cib/list/Catalog.Companies" );
	With ( "Companies" );
	Clear ( "#UnitFilter" );
	GotoRow ( "#List", "Description", "SuperX" );
	Click ( "#FormSetDeletionMark" );
	Click ( "Yes", "1?:*" );

EndProcedure