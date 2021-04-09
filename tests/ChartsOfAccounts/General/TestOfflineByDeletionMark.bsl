Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/ChartOfAccounts.General" );
list = With ();
Click ( "#FormShowOffline" );
p = Call ( "Common.Find.Params" );
p.What = "40120";
p.Where = "Code";
Call ( "Common.Find", p );
Click ( "#FormSetDeletionMark" );
Click("Yes", "1?:*");
Click ( "#FormChange" );


With ();

if ( Fetch ( "#Offline" ) <> "Yes" ) then
	Stop ( "Offline must be true" );
endif;
Close ();

With ( list );
Click ( "#FormSetDeletionMark" );
Click("Yes", "1?:*");
Click ( "#FormChange" );
With ();

if ( Fetch ( "#Offline" ) <> "No" ) then
	Stop ( "Offline must be false" );
endif;
