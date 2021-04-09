// Create Item
// Add Property: range
// Try to use new property
// Open properties again and check if they still are there

Call ( "Common.Init" );
CloseAll ();

itemName = "Some: " + CurrentDate ();

// Create Item
Call ( "Common.OpenList", _ );
Click ( "#FormCreate" );
form = With ( "* (cr*" );

// Add Property: range
Pick ( "#ObjectUsage", "Current Object Settings" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );
Set ( "#TreeName", itemName, table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Range" );
Pick ( "#TreeType", "Number" );
Set ( "#TreeMinimum", 100 );
Set ( "#TreeMaximum", 200 );

Click ( "#FormOK" );

With ( form );

// Try to use new property
Set ( "Range", 150 );
Next ();

Set ( "Range", 250 ); // wrong value
Next ();
if ( Waiting ( "1?:*" ) ) then
	Click ( "Cancel entry", "1?:*" );
else
	Stop ( "The messagebox <Incorrect data entered into field> should appear" );
endif;

// Open properties again and check if they still are there
Click ( "#OpenObjectUsage" );
With ( "Properties*" );
table = Activate ( "#Tree" );
GotoRow ( "#Tree", "Description", "Range" );
Check ( "#TreeMinimum", 100 );
Check ( "#TreeMaximum", 200 );
