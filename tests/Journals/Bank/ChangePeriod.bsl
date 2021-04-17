// Open Bank journal
// Change period
// Close journal
// Open journal again and check if period is the same

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/InformationRegister.Bank" );
With ( "Bank" );

Pick ( "#Period", "This year" );
Close ();

Commando ( "e1cib/list/InformationRegister.Bank" );
With ( "Bank" );
Check ( "#Period", "This year" );
