StandardProcessing = false;

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.UserSettings" );
form = CurrentSource;
form1 = With ( "*(User Settings)" );
f = Activate ( "#Company" );
f.Open ();
form2 = With ( "*(Companies)" );
status = ( "Yes" = Fetch ( "Options / #CostOnline" ) );
if ( status <> _ ) then
	Click ( "#CostOnline" );
	Click ( "#FormWrite" );
endif;
Close ( form2 );
Close ( form1 );

With ( form );