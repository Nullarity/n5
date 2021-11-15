// Description:
// Creates a new Customs group
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.CustomsGroups" );
form = With ( "Customs Groups (create)" );

default = ( _ = undefined );
name = ? ( default, "_Customs Groups: " + Call ( "Common.GetID" ), _.Description );

//DebugStart ();
Put ( "#Description", name );

table = Activate ( "#Charges" );
if ( default ) then
	Click ( "#ChargesAdd" );
	Set ( "#ChargesCharge", "Плата за таможенные процедуры, 010", table );
	Set ( "#ChargesPercent", "10", table );
	
	Click ( "#ChargesAdd" );
	Set ( "#ChargesCharge", "НДС, 030", table );
	
else
	for each row in _.Payments do
		Click ( "#ChargesAdd" );
		if ( row.Percent = undefined ) then
			Put ( "#ChargesCharge", row.Payment, table );
		else
			Set ( "#ChargesCharge", row.Payment, table );
			Set ( "#ChargesPercent", row.Percent, table );
		endif;	
	enddo;
endif;

With ();
Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new structure ( "Code, Description", code, name );