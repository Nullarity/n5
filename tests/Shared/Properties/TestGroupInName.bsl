Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Create folder with properties
// ***********************************

list = Call ( "Common.OpenList", _ );
Click ( "#FormCreateFolder" );
form = With ( "* (create*" );
Pick ( "#ObjectUsage", "Current Object Settings" );
Click ( "#OpenObjectUsage" );
With ( DialogsTitle );
Click ( "Yes" );

// ***********************************
// Create properties
// ***********************************

With ( "Properties*" );
table = Activate ( "#Tree" );

Click ( "#TreeAddGroup" );
Set ( "#TreeName", "Properties", table );
Click ( "#TreeInName2" );
descriptionExists =  _ <> Meta.Catalogs.Features;
if ( descriptionExists ) then
	Click ( "#TreeInDescription2" );
endif;

Click ( "#TreeAdd" );
Set ( "#TreeName", "Color", table );

Click ( "#TreeAdd" );
Set ( "#TreeName", "Smell", table );

Click ( "#FormOK" );

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

// ***********************************
// Fill properties
// ***********************************
id = " " + Call ( "Common.GetID" );
Set ( "Color", "green" );
Set ( "Smell", "rose" + id );

// ***********************************
// Check name, description
// ***********************************

Click ( "#FormWrite" );
Check ( "#Description", "Properties: green, rose" + id );
CheckState ( "#Description", "ReadOnly" );
if ( descriptionExists ) then
	Check ( "#FullDescription", "Properties: green, rose" + id );
	CheckState ( "#FullDescription", "ReadOnly" );
endif;

Click ( "#FormWrite" );