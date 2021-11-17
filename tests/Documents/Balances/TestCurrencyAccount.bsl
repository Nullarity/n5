// Create a new Opening Balance
// Set currency account
// Check calculations
// Post the document

Call ( "Common.Init" );
CloseAll ();

// Create document
Commando ( "e1cib/list/DocumentJournal.Balances" );
With ( "Opening Balances" );
Click ( "#FormCreateByParameterBalances" );
With ( "Opening Balances (cr*" );

Put ( "#Account", "2421" );
table = Get ( "#Details" );
Set ( "#DetailsCurrency", "CAD", table );
Set ( "#DetailsCurrencyAmount", 100, table );
Check ( "#DetailsAmount", 80, table );

Set ( "#DetailsRate", 0.5, table );
Check ( "#DetailsAmount", 50, table );

Click ( "#FormPost" );
Click ( "#FormReportRecordsShow" );
With ( "Records:*" );
Call ( "Common.CheckLogic", "#TabDoc" );
