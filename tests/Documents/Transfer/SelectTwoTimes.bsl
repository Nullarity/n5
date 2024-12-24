// Just select some item two times

Call ( "Common.Init" );
CloseAll ();


Commando ( "e1cib/command/Document.Transfer.Create" );
Click ( "#ItemsSelectItems" );

With ();
if ( Fetch ( "#AskDetails" ) = "No" ) then
	Click ( "#AskDetails" );
endif;
Get ( "#ItemsList" ).Choose ();
Get ( "#FeaturesList" ).Choose ();

With ();
Click ( "#FormOK" );

With ();
Get ( "#ItemsList" ).Choose ();
Get ( "#FeaturesList" ).Choose ();

With ();
Click ( "#FormOK" );

With ();
Click ( "#FormOK" );
