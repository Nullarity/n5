Call ( "Common.Init" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Currencies" );
With ( "Currencies" );
p = Call ( "Common.Find.Params" );
p.Where = "Code";
p.What = "USD";
Call ( "Common.Find", p );
Click ( "#FormChange" );

With ( "USD (*" );
Put ( "#GenderIntRo", "Male" );
Put ( "#SingularIntRo", "dolar" );
Put ( "#PlurarIntRo", "dolari" );

Put ( "#GenderFractionalRo", "Male" );
Put ( "#SingularFractionalRo", "cent" );
Put ( "#PlurarFractionalRo", "centi" );

Put ( "#AmountRo", "2557.67" );
Put ( "#GenderIntRo", "Male" );

correct = "Două mii cinci sute cincizeci şi şapte dolari 67 centi";
if ( Fetch ( "#InWordsRo" ) <> correct ) then
	stop ( "Must be: " + correct );
endif;	



