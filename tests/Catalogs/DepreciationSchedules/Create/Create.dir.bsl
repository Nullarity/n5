// Description:
// Creates a new PaymentOption
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.DepreciationSchedules" );

form = With ( "Depreciation Schedules (create)" );
if ( _ = undefined ) then
	name = "_Schedule: " + CurrentDate ();
else
	name = _.Description;
endif;

Set ( "#Description", name );

for i = 1 to 12 do
	value = _ [ "Rate" + i ];
	if ( value = 0 ) then
		continue;
	endif;
	Put ( "#Rate" + i, value );
enddo;

Click ( "#FormWrite" );
code = Fetch ( "Code" );
Close ();

return new Structure ( "Code, Description", code, name );


