records ( _.Assets, _.Date );

// ***********************************
// Procedures
// ***********************************

Function records ( Assets, Date )
	
	if ( Call ( "Common.AppIsCont" ) ) then
		expenseAccount = "7141";
		amortizationAccount = "1241";
	else
		expenseAccount = "8111";
		amortizationAccount = "17000";
	endif;

	p = Call ( "Documents.Entry.Create.Params" );
	records = new Array ();
	for each row in Assets do
		records.Add ( newRecord ( expenseAccount, amortizationAccount, row.Amount, row.Asset ) );
	enddo;	
	p.Records = records;
	p.Date = Call ( "Common.USFormat", Date );//Format ( Date, "DF='MM/dd/yyyy hh:mm:ss tt'" );
	Call ( "Documents.Entry.Create", p );
	return records;

EndFunction

Function newRecord ( AccountDr, AccountCr, Amount, DimCr1 )

 	p = Call ( "Documents.Entry.Create.Row" );
	p.AccountDr = AccountDr;
	p.AccountCr = AccountCr;
	p.Amount = Amount;
	p.DimCr1 = DimCr1;
	return p;

EndFunction