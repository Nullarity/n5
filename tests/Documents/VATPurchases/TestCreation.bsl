Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.VATPurchases" );
With ( "VAT on Purchases (cr*" );

date = BegOfDay ( CurrentDate () );
Set ( "#Date", Format ( date, "DLF=D" ) );
Next ();
Check ( "#RecordDate", date );
Put ( "#Amount", 100 );
Put ( "#VATCode", "20%" );
Check ( "#VAT", 16.67 );
Set ( "#VATUse", "Not Included" );
Check ( "#VAT", "20" );

series = "aaa";
number = Call ( "Common.GetID" );
id = Upper ( series ) + number;
Set ( "#Series", series );
Set ( "#FormNumber", number );
Next ();
Check ( "#Number", id );

Click ( "#FormWrite" );