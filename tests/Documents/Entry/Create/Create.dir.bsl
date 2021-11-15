// Description:
// Create & post a new Entry document
//
// Parameters:
// Documents.Entry.Create.Params
//
// Returns:
// Structure ( "Date, Number" )

MainWindow.ExecuteCommand ( "e1cib/data/Document.Entry" );
form = With ( "Entry (cr*" );

// ***********************************
// Fill header
// ***********************************

date = _.Date;
Put ( "#Date", date );
Put ( "#Company", _.Company );
Put ( "#Memo", _.Company );

// ***********************************
// Fill table
// ***********************************

for each row in _.Records do
	Click ( "#RecordsAdd" );
	With ( "Record" );
	Put ( "#AccountDr", row.AccountDr );
	Put ( "#AccountCr", row.AccountCr );
	value = row.DimDr1;
	if ( value <> undefined ) then 
		Put ( "#DimDr1", value );
	endif;
	value = row.DimDr2;
	if ( value <> undefined ) then 
		Put ( "#DimDr2", value );
	endif;
	value = row.DimCr1;
	if ( value <> undefined ) then 
		Put ( "#DimCr1", value );
	endif;
	value = row.DimCr2;
	if ( value <> undefined ) then 
		Put ( "#DimCr2", value );
	endif;
	value = row.QuantityDr;
	if ( value <> undefined ) then 
		Set ( "#QuantityDr", value );
	endif;
	value = row.QuantityCr;
	if ( value <> undefined ) then 
		Set ( "#QuantityCr", value );
	endif;
	value = row.CurrencyDr;
	if ( value <> undefined ) then 
		Set ( "#CurrencyDr", value );
	endif;
	value = row.CurrencyCr;
	if ( value <> undefined ) then 
		Set ( "#CurrencyCr", value );
	endif;
	value = row.CurrencyAmountDr;
	if ( value <> undefined ) then 
		Set ( "#CurrencyAmountDr", value );
	endif;
	value = row.CurrencyAmountCr;
	if ( value <> undefined ) then 
		Set ( "#CurrencyAmountCr", value );
	endif;
	value = row.Amount;
	if ( value <> undefined ) then 
		Set ( "#Amount", value );
	endif;
	Click ( "#FormOK" );
	With ( form );
enddo;

// ***********************************
// Post and return
// ***********************************

Click ( "#FormPost" );
number = Fetch ( "#Number" );
With();
Close ();
return new Structure ( "Date, Number", date, number );





