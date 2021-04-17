StandardProcessing = false;

form = With ( "Download Currencies" );

tomorow = Format ( EndOfDay ( CurrentDate () ) + 1, "DLF=D" );
Set ( "#DateStart", tomorow );
Set ( "#DateEnd", tomorow );

Click ( "#FormDownload", form.GetCommandBar () );

if ( App.GetActiveWindow ().GetUserMessageTexts ().Count () = 0 ) then
	Message ( "Error message should be appeared" );
	Stop ();
endif;
Close ();
