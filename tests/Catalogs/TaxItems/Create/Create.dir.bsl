// Description:
// Creates a new Tax Item
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.TaxItems" );

form = With ( "Tax Items (create)" );

if ( _ = undefined ) then
	name = "_TaxItem: " + CurrentDate ();
	percent = 5;
	account = "25500";
	period = "01/01/1980";
else
	name = _.Description;
	percent = _.Percent;
	account = _.Account;
	period = _.Period;
endif;

Set ( "Description", name );
Set ( "Account", account );

Click ( "#FormWrite" );
code = Fetch ( "Code" );

// ***********************************
// Add Percent
// ***********************************

register = "Sales Tax Percentage";
Click ( register, GetLinks () );
form = With ( register );
Click ( "#FormCreate" );
With ( register + " (create)" );
Set ( "#Period", period );
Set ( "#Percent", percent );
Click ( "#FormWriteAndClose" );
Close ( form );
return new Structure ( "Code, Description", code, name );
