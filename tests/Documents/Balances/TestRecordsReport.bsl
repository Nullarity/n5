// Open balances list
// Create, Save & Close a new Opening Balance
// Click DrCr button

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

// Generate report
With ( list );
Click ( "#FormShowRecords" );
