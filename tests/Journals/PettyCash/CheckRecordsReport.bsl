// Scenario:
// - Open Journal
// - Add a new Customer Payment
// - Check DrCr ToolTip
// - Generate Records Report

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
With ( "Customer Payment (cr*" );
Set ( "#Method", "Cash" );
Click ( "#FormWrite" );
number = Fetch ( "#Number" );
Close ();

// Check DrCr tooltip
With ( list );
Click ( "#FormShowRecords" );
With ( "Records: *" + number + "*" );