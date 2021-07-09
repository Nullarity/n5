// Create time entry and pick some item

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Document.TimeEntry.Create");
Activate ( "Items" );
Click ( "#ItemsSelectItems" );             

With ( "Items Selection" );
if ( Fetch ( "#AskDetails" ) = "Yes" ) then
	Click ( "#AskDetails" );
endif;
ItemsList = Get ( "#ItemsList" );
ItemsList.GotoLastRow ();
ItemsList.Choose ();
Get ( "#FeaturesList" ).Choose ();

With ();
Click ( "#FormOK" );

CheckErrors ();

With ();
Assert ( Call ( "Table.Count", Get ( "#ItemsTable" ) ) ).Equal ( 1 );

Disconnect ();