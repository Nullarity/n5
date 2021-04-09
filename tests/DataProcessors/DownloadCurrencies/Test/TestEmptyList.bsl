StandardProcessing = false;

With ( "Download Currencies" );
Activate ( "#List" );
Click ( "#ListUnMarkAll" );
Click ( "#FormDownload" );

if ( App.GetActiveWindow ().GetUserMessageTexts ().Count () = 0 ) then
	Message ( "Error message should be appeared" );
	Stop ();
endif;

Close ();