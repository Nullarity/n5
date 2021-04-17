
MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Projects" );
With ( "Projects (create)" );
Set ( "#Owner", _.Customer );
Set ( "#Description", _.Description );
value = _.ProjectType;
if ( value <> undefined ) then
	Set ( "#ProjectType", value );
endif;
Set ( "#DateStart", _.DateStart );
Click ( "#FormWrite" );
code = Fetch ( "#Code" );
Close ();
return code;
