Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Accounting / Account Analysis" );
With ( "Account Analysis*" );

IgnoreErrors = true;
Click ( "#GenerateReport" );

if ( FindMessages ( "Field * is empty" ).Count () = 0 ) then
	Stop ( "<Field Account is empty> message box must be shown" );
endif;
IgnoreErrors = false;
Close ();
