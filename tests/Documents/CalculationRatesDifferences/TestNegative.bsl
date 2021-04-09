// *************************
// Create CalculationRatesDifferences test positive differences
// *************************

Commando ( "e1cib/list/Document.CalculationRatesDifferences" );
With ();
p = Call ( "Common.Find.Params" );
p.What = _.ID + " Negative";
p.Where = "Memo";
Call ( "Common.Find", p );
try
	Click ( "#FormChange" );
	With ( "Calculation of Rates Differences #*" );
	Click ( "#FormUndoPosting" );
except
	Click ( "#FormCreate" );
	With ();
endtry;

Put ( "#Date", "03/02/2018" );
Put ( "#Memo", _.id + " Negative" );
Put ( "#Company", _.Company );
Put ( "#AccountPositive", "70100" );
Put ( "#AccountNegative", "8111" );
Put ( "#Dim1", _.Expenses );
Put ( "#Dim2", "Administration" );
Put ( "#CashFlow", _.CashFlow );
Click ( "#FormPost" );

Click ( "#FormReportRecordsShow" );
CheckTemplate ( "#TabDoc", "Records: *" );
