
Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Settings / Application" );
With ( "Application Settings" );

pages = new Array ();
pages.Add ( "General" );
pages.Add ( "Features" );
pages.Add ( "Customers & Vendors" );
pages.Add ( "Items" );
pages.Add ( "Accounting" );
pages.Add ( "Employees" );
pages.Add ( "Database" );

begin = true;
for each page in pages do
	if ( begin ) then
		begin = false;
		CheckState ( "#FormPreviuosStep", "Enable", false );
	else
		Click ( "#FormNextStep" );
	endif;
	if ( getTab () = page ) then
		continue;
	endif;
	Stop ( "Page <" + page + "> should be active" );
enddo;

CheckState ( "#FormNextStep", "Enable", false );

// ***********************************
// Functions
// ***********************************

Function getTab ()

	return CurrentTab ( "#Pages" ).TitleText;

EndFunction