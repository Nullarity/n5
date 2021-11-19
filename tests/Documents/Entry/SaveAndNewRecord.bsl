// Create Entry
// Add Record
// Add new record by pressing Save and New button
// Check totals
// Check posting

Call ( "Common.Init" );

// Create Entry
try
	Commando ( "e1cib/data/Document.Entry" );
except
	DebugStart ();
endtry;
form = With ( "Entry (cr*" );

// Add Record
Click ( "#RecordsAdd" );
With ( "Record" );
try
	Put ( "#AccountDr", "2421" );
except
	DebugStart ();
endtry;
Put ( "#AccountCr", "0" );
Set ( "#Amount", 100 );

// Add new record by pressing Save and New button
Click ( "#FormSaveAndNew" );
With ( "Record" );
Put ( "#AccountDr", "2421" );
Put ( "#AccountCr", "0" );
Set ( "#Amount", 50 );
Click ( "#FormOK" );

// Check totals
With ( form );
Check ( "#RecordsTotalAmountDr", 150 );

// Check posting
Click ( "#FormPostAndClose" );
