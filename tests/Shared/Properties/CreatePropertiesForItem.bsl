
Call ( "Common.Init" );
CloseAll ();

__ = "Motorola" + " " + Call ( "Common.GetID" );

// ***********************************
// Create folder with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );

// ***********************************
// Create properties
// ***********************************

Pick ( "#ItemsUsage", "Current Object Settings" );
Click ( "#OpenItemsUsage" );
With ( DialogsTitle );
Click ( "Yes" );

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );
Set ( "#TreeName", "Station", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Class", table );
Click ( "#TreeInName" );
descriptionExists =  _ <> Meta.Catalogs.Features;
if ( descriptionExists ) then
	Click ( "#TreeLabelDescription" );
endif;

Click ( "#TreeAdd" );
Set ( "#TreeName", "Brand", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Type", table );

Click ( "#TreeAddGroup" );
Set ( "#TreeName", "Frequency", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "from", table );
Set ( "#TreeDefaultValue", "50FM" );
Click ( "#TreeLabelName" );
if ( descriptionExists ) then
	Click ( "#TreeLabelDescription" );
endif;

Click ( "#TreeAdd" );
Set ( "#TreeName", "to", table );
Set ( "#TreeDefaultValue", "150FM" );
Click ( "#TreeLabelName" );
if ( descriptionExists ) then
	Click ( "#TreeLabelDescription" );
endif;

Click ( "#FormOK" );

With ( form );

// ***********************************
// Open & apply properties again:
// test properties serialization
// ***********************************

Click ( "#OpenItemsUsage" );
With ( "Properties*" );
Click ( "#FormOK" );

With ( form );
Click ( "#FormWrite" );
code = Fetch ( "#Code" );

// ***********************************
// Navigate & expand this folder
// ***********************************

Close ();
With ( list );

caption = Call ( "Common.Meta.Caption", _ );
With ( caption );

table = Get ( "#List" );
table.GotoFirstRow ();
search = new Map ();
search [ "Code" ] = code;
table.GotoRow ( search );
table.Choose ();

// ***********************************
// Create a new Item
// ***********************************

Click ( "#FormCreate" );
With ( "* (crea*" );
setData ();

// ***********************************
// Check name, description
// ***********************************

Activate ( "#Description" );
Check ( "#Description", "Station " + __ + ", GM340, from: 136, to: 174" );
CheckState ( "#Description", "ReadOnly" );
if ( descriptionExists ) then
	Check ( "#FullDescription", "Station Class: mobile, " + __ + ", GM340, from: 136, to: 174" );
	CheckState ( "#FullDescription", "ReadOnly" );
endif;

// ************************************************
// Save & Reread properties for testing saved data
// ************************************************

Click ( "#FormWrite" );
Click ( "#FormReread" );
checkData ();

// ***********************************
// Functions
// ***********************************

Procedure setData ()

	for each item in fieldValues () do
		Set ( item.Field, item.Value );
	enddo;

EndProcedure

Function fieldValues ()

	data = new Array ();
	data.Add ( new Structure ( "Field, Value", "Class", "mobile" ) );
	data.Add ( new Structure ( "Field, Value", "Brand", __ ) );
	data.Add ( new Structure ( "Field, Value", "#PropertiesGroup / Type", "GM340" ) );
	data.Add ( new Structure ( "Field, Value", "from", "136" ) );
	data.Add ( new Structure ( "Field, Value", "to", "174" ) );
	return data;

EndFunction

Procedure checkData ()

	for each item in fieldValues () do
		Check ( item.Field, item.Value );
	enddo;

EndProcedure
