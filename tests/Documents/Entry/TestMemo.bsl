Call ( "Common.Init" );
CloseAll ();

id = "2725E106";

Commando ("e1cib/data/Document.Entry");
form = With ( "Entry (create)" );

Click ( "#RecordsAdd" );

With ( "Record" );
Put ( "#AccountDr", "0" );
Put ( "#AccountCr", "0" );
Put ( "#Content", id );
Click ( "#FormOK" );

With ( form );
Check ( "#Memo", id );