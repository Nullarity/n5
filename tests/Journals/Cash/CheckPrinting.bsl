// Scenario:
// - Open Journal
// - Add a new Customer Payment
// - Open Receipt & Print from Receipt
// - Close Receipt & Print from Customer Payment
// - Close Customer Payment & Print from Journal

Call ( "Common.Init" );
CloseAll ();

// ************
// Open Journal
// ************

Commando ( "e1cib/list/DocumentJournal.PettyCash" );
list = With ( "Petty Cash" );

Activate ( "#List" );
Click ( "#FormCreateDocument" );
CurrentSource.ExecuteChoiceFromMenu ( "Customer Payment" );
form = With ( "Customer Payment (cr*" );
Set ( "#Method", "Cash" );
Click ( "#FormWrite" );

// ******************
// Print from Receipt
// ******************

Click ( "#Receipt" );
With ( "Cash Receipt" );
Set ( "#Reference", "It enforces system to save modified" );
Click ( "#FormPrint" );
Close ( "Receipt: Print" );
Close ( "Cash Receipt" );

// ***************************
// Print from Customer Payment
// ***************************

With ( form );
Click ( "#FormReceipt" );
Close ( "Receipt: Print" );
Close ( form );

// *****************************
// Print from Petty Cash Journal
// *****************************

With ( list );
Click ( "#FormPrint" );
Close ( "Receipt: Print" );
