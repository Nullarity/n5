Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Numeration" );
Set ( "#Description", Right ( Call ( "Common.GetID" ), 3 ) );
Set ( "#Code", "000000000000" );
Next ();
code = Fetch ( "#Code" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/data/Document.Entry" );
Put ( "#Number", "0000000000000000000000000000000" );
Next ();
number = Fetch ( "#Number" );
if ( StrLen ( code ) <> StrLen ( number ) + 3 ) then
	Stop ( "Numeration code and Entry code don't correspond" );
endif;

