// Open balances list
// Create, Save & Close a new Opening Balance
// Copy that document
// Check copied account

Call ( "Common.Init" );
CloseAll ();

// Create document
Commando ( "e1cib/list/DocumentJournal.Balances" );
list = With ( "Opening Balances" );
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );
account = "10300";
Put ( "#Account", account );
Click ( "#FormPostAndClose" );

// Copy
With ( list );
Click ( "#FormCopy" );
With ( "Opening Balances (cr*" );
Check ( "#Account", account );