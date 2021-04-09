// Description:
// Creates a new Holidays list
//
// Parameters:
// Catalogs.Holidays.Create.Params
//
// Returns:
// Structure ( "Code, Description" )

Commando ( "e1cib/data/Catalog.Holidays" );
form = With ( "Holidays (cr*" );
description = _.Description;
Set ( "#Description", description );
Set ( "#Year", Format ( _.Year, "NG=0" ) );
Click ( "#Write" );

for each day in _.Days do
	Click ( "#HolidaysCreate" );
	With ( "Holidays (cr*" );
	Set ( "#Day", Format ( day.Day, "DLF=D;L=en_US" ) );
	Set ( "#Description", day.Title );
	Click ( "#FormWriteAndClose" );
	With ( form );
enddo;

code = Fetch ( "#Code" );
Close ();
return new Structure ( "Code, Description", code, _.Description );
