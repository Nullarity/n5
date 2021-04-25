StandardProcessing = false;
form = CurrentSource;
Commando ( "e1cib/command/Catalog.UserSettings.Command.Show" );
form1 = With ();
f = Activate ( "#Company" );
f.Open ();
form2 = With ();
status = ( "Yes" = Fetch ( "#CostOnline" ) );
if ( status <> _ ) then
	Click ( "#CostOnline" );
	Click ( "#FormWrite" );
endif;
Close ( form2 );
Close ( form1 );
CurrentSource = form;