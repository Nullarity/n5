Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Numeration" );
form = With ( "Numeration (create)" );
Put ( "#Code", "0000000000000000000000000000000" );
Next ();
code = Fetch ( "#Code" );

Commando ( "e1cib/data/Document.Entry" );
entry = With ( "Entry (create)" );
Put ( "#Number", "0000000000000000000000000000000" );
Next ();
number = Fetch ( "#Number", entry );
if ( StrLen ( code ) <> StrLen ( number ) + 3 ) then
	Stop ( "Numeration code and Entry code don't correspond" );
endif;

