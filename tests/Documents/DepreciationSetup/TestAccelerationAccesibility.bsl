Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/data/Document.DepreciationSetup" );
With ( "Depreciation Setup (create)" );

Click ( "#MethodChange" );
Put ( "#Method", "Linear" );
checkAcceleration ();

Put ( "#Method", "Decreasing" );
Put ( "#Acceleration", 1 );

Clear ( "#Method" );	

checkAcceleration ();

Procedure checkAcceleration ()

	try
		Put ( "#Acceleration", 1 );
		error = false;
	except
		error = true;
	endtry;

	if ( not error ) then
		Stop ( "<Acceleration> Must be disabled" );
	endif;

EndProcedure


