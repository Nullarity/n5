// Scenario:
// - Open Journal
// - Add new Customer Payment
// - Save document
// - Copy document

Call ( "Common.Init" );
CloseAll ();

// ************
// Open Journal
// ************

Commando ( "e1cib/list/DocumentJournal.Cash" );
list = With ( "Petty Cash" );

Activate ( "#List" );
Click ( "#FormCreateDocument" );
CurrentSource.ExecuteChoiceFromMenu ( "Customer Payment" );
With ( "Customer Payment (cr*" );
amount = 321;
Set ( "#Amount", amount );
Set ( "#Method", "Cash" );
Click ( "#FormWrite" );
Close ();

// Copy
With ( list );
Click ( "#FormCopy" );
With ( "Customer Payment (cr*" );
Check ( "#Amount", amount );
