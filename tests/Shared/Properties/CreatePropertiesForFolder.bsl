Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create folder with properties
// ***********************************

Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );

// ***********************************
// Test Wrong Inheritance
// ***********************************

Pick ( "#ObjectUsage", "Inherit From Parent Folder" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Get ( "* not found" ); // Error message must be shown
Click ( "OK" );

// ***********************************
// Fix the problem and continue
// ***********************************

With ( form );
Pick ( "#ObjectUsage", "Current Object Settings" );

// ***********************************
// Create properties
// ***********************************

Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );
With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#AddLabel" );
Set ( "#TreeName", "Station", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Class", table );
Click ( "#TreeInName" );

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
descriptionExists =  _ <> Meta.Catalogs.Features;
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

// ***********************************
// Fill properties
// ***********************************

With ( form );
code = Fetch ( "#Code" );
Close ( form );
With ();
try
	Clear ( "#WarehouseFilter" );
except
endtry;	
p = Call ( "Common.Find.Params" );
p.Where = "Code";
p.What = code;
Call ( "Common.Find", p );

Click ( "#ListContextMenuChange" );
form = With ();
brand = "Motorola" + " " + Call ( "Common.GetID" );
Set ( "Class", "mobile" );
Set ( "Brand", brand );
Set ( "Type", "GM340" );
Set ( "from", "136" );
Set ( "to", "174" );

// ***********************************
// Save, Open & Close properties again
// ***********************************

Click ( "#FormWrite" );
Click ( "#OpenObjectUsage" );
With ( "Properties*" );
Click ( "#FormClose" );
With ( form );

// ***********************************
// Check name, description
// ***********************************

Check ( "#Description", "Station " + brand + ", GM340, from: 136, to: 174" );
CheckState ( "#Description", "ReadOnly" );
if ( descriptionExists ) then
	Check ( "#FullDescription", "Station mobile, " + brand + ", GM340, from: 136, to: 174" );
	CheckState ( "#FullDescription", "ReadOnly" );
endif;


