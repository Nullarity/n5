// Description:
// Creates a new Tax Group
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.TaxGroups" );

form = With ( "Sales Tax Groups (create)" );

if ( _ = undefined ) then
	name = "_SalesGroup: " + CurrentDate ();
	taxes = new Array ();
else
	name = _.Description;
	taxes = _.Taxes;
endif;

Set ( "Description", name );
table = Activate ( "#Taxes" );
for each row in taxes do
	Click ( "#TaxesAdd" );
	
	name = row.Description;
	params = Call ( "Common.Select.Params" );
	params.Object = Meta.Catalogs.TaxItems;
	params.Search = name;
	params.QuickChoice = true;
	params.Field = Get ( "#TaxesTax", table );
	creation = Call ( "Catalogs.TaxItems.Create.Params" );
	creation.Description = name;
	creation.Percent = row.Percent;
	params.CreationParams = creation;
	Call ( "Common.Select", params );
	
	With ( form );
	
	Set ( "#TaxesTax", name, table );
enddo;

Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();
return new Structure ( "Code, Description", code, name );
