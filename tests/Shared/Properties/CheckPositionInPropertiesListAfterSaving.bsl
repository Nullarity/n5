start ();

// ***********************************
// Create item with properties
// ***********************************

form = newItem ( _ );

// ***********************************
// Create properties
// ***********************************

Pick ( "#ObjectUsage", "Current Object Settings" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#TreeAdd" );
propertyName = "Bolt type";
Set ( "#TreeName1", propertyName );
CurrentSource.GotoNextItem ();

Click ( "#FormSave" );

// Current Line must be the same after saving
table = Get ( "#Tree" );
Check ( "#TreeName", propertyName, table );

// ***********************************
// Functions
// ***********************************

Procedure start ()

	Call ( "Common.Init" );
	CloseAll ();

EndProcedure

Function newItem ( Obj )

	list = Call ( "Common.OpenList", Obj );
	Click ( "#FormCreate" );
	return With ( "* (create*" );

EndFunction
