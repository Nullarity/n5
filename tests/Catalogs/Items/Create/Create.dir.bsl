// Description:
// Creates a new Item
//
// Returns:
// Structure ( "Code, Description" )

Pause (1);
MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Items" );
form = With ( "Items (create)" );
if ( _ = undefined ) then
	name = "_Item: " + CurrentDate ();
	countPkg = false;
	service = false;
	product = false;
	costMtd = false;
	feature = undefined;
	useCustomsGroup = false;
	itemType = undefined;
	package = "PK";
	capacity = 5;
	barcode = undefined;
	series = false;
else
	name = _.Description;
	countPkg = _.CountPackages;
	service = _.Service;
	product = _.Product;
	if ( _.CostMethod = undefined ) then
		costMtd = false;
	else
		costMtd = true;
	endif;
	feature = ? ( _.Feature = undefined, undefined, _.Feature );
	useCustomsGroup = _.UseCustomsGroup;
	itemType = _.ItemType;
	package = ? ( _.Unit = undefined, "PK", _.Unit );
	capacity = ? ( _.Capacity = undefined, 5, _.Capacity );
	barcode = _.Barcode;
	series = _.Series;
endif;
With ();
Set ( "#Description", name );

if ( service ) then
	Click ( "#Service" );
endif;
if ( product ) then
	Click ( "#Product" );
endif;
if ( series ) then
	Click ( "#Series" );
endif;
if ( itemType <> undefined ) then
	Set ( "#ItemType", itemType );
endif;

if ( AppName = "c5" ) then
	if ( _ <> undefined ) then
		value = _.VAT;
		if ( value <> undefined ) then
			Set ( "#VAT", value );
		endif;
		if ( _.Social ) then
			Click ( "#Social" );
		endif;
		if ( not service
			and _.OfficialCode <> undefined ) then
			Put ( "#OfficialCode", _.OfficialCode );
		endif;
		if ( _.Form ) then
			Click ( "#ItemForm" );
		endif;
	endif;	
endif;

Click ( "#FormWrite" );

unit = TrimAll ( Fetch ( "#Unit" ) );

if ( not service ) then
	field = Activate ( "#Package" );
	if ( Fetch ("#Package") <> package ) then
		try
			field.OpenDropList ();
		except
		endtry;
		try
			field.Create ();
		except
			DebugStart ();
		endtry;	
		With ( "Packages (create)" );
		
		Set ( "#Unit", package );
		Set ( "#Capacity", capacity );
		Click ( "#FormWriteAndClose" );
	
		With ( form );
	endif;
	if ( countPkg ) then
		Click ( "#CountPackages" );
		Click ( "Yes", Forms.Get1C () ); // Closes 1C standard dialog
	endif;
	if ( costMtd ) then
		Set ( "#CostMethod", _.CostMethod );
	endif;
endif;

if ( useCustomsGroup ) then
	Put ( "#CustomsGroup", _.CustomsGroup );
endif;

Click ( "#FormWrite" );
code = Fetch ( "Code" );

if ( feature <> undefined ) then
	Click ( "Features", GetLinks () );
	featuresList = With ( "Features" );
	Click ( "#FormCreate" );
	With ( "Features (create)" );
	Set ( "#Description", feature );
	Click ( "#FormWriteAndClose" );
	With ( featuresList );
endif;

if ( barcode <> undefined ) then
	Click ( "Barcodes", GetLinks () );
	barcodeList = With ( "Barcodes" );
	Click ( "#FormCreate" );
	With ();
	Set ( "#Barcode", barcode );
	Click ( "#FormWriteAndClose" );
	With ( barcodeList );
endif;

Close ();

return new Structure ( "Code, Description", code, name );
