// - Open list of entries
// - Create entry from that list
// - Check amount in the list

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/Document.Entry" );
list = With ( "Accounting Entries" );

Click ( "#FormCreate" );
With ( "Entry (cr*" );

Click ( "#Simple" );
Activate ( "#OneRecordPage" );
amount = 100;
Set ( "#RecordAmount", amount );

Click ( "#FormWrite" );
Close ();

With ( list );
Check ( "#Amount", amount, Get ( "#List" ) );
