// Description:
// Creates a new PaymentOption
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Departments" );

form = With ( "Departments (create)" );
if ( _ = undefined ) then
	name = "_Department: " + CurrentDate ();
	company = undefined;
	shipments = undefined;
	production = undefined;
	products = undefined;
	division = undefined;
else
	name = _.Description;
	company = _.Company;
	shipments = _.Shipments;
	production = _.Production;
	products = _.Products;
	if ( AppName = "c5" ) then
		division = _.Division;
	endif;	
endif;

Set ( "Description", name );

if ( company <> undefined ) then
	Set ( "#Owner", company );
endif;

if ( shipments <> undefined ) then
	click = ? ( shipments, "Yes", "No" ) <> Fetch ( "#Shipments" );
	if ( click ) then
		Click ( "#Shipments" );
	endif;
endif;

if ( production <> undefined ) then
	click = ? ( production, "Yes", "No" ) <> Fetch ( "#Production" );
	if ( click ) then
		Click ( "#Production" );
	endif;
endif;
if ( products <> undefined ) then
	Click("#FormWrite");
	for each item in Conversion.StringToArray (products) do
		Click("#DepartmentItemsCreate");
		With();
		Set("#Item", item);
		Click("#FormWriteAndClose");
		With();
	enddo;
endif;

if ( division <> undefined ) then
	Put ( "#Division", division );
endif;

Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new Structure ( "Code, Description", code, name );
