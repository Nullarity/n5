// - Create general currencies list

Call ( "Common.Init" );

CloseAll ();

list = new Array ();
list.Add ( "MDL" );
list.Add ( "USD" );
list.Add ( "EUR" );
list.Add ( "RON" );
list.Add ( "UAH" );
list.Add ( "RUB" );
list.Add ( "BGN" );
list.Add ( "KZT" );

Commando ( "e1cib/list/Catalog.Currencies" );
for each code in list do

	With ( "Currencies" );
	Click ( "#FormCreate" );
	With ( "Classifier" );

	GotoRow ( "#List", "Code", code );
	Click ( "#FormSelect" );

enddo;

fill ( "MDL", "Male", "leu", "lei", "Male", "ban", "bani", "leu", "lei", "ban", "bani" );
fill ( "USD", "Male", "dolar", "dolari", "Male", "cent", "cenţi", "dollar", "dollars", "cent", "cents" );
fill ( "EUR", "Male", "euro", "euro", "Male", "eurocent", "eurocenţi", "euro", "euro", "euro cent", "euro cents" );
fillRu ( "MDL", "Male", "лей", "лея", "лей", "Male", "бан", "баня", "бань" );
fillRu ( "USD", "Male", "доллар", "доллара", "долларов", "Male", "цент", "цента", "центов" );
fillRu ( "EUR", "Female", "евро", "евро", "евро", "Male", "цент", "цента", "центов" );

//********************
//	Procedures
//********************

Procedure fill ( Code, GenderIntRo, SingularIntRo, PlurarIntRo, GenderFractionalRo,	SingularFractionalRo, PlurarFractionalRo, SingularIntEn, PlurarIntEn, SingularFractionalEn,	PlurarFractionalEn )

	With ( "Currencies" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Code";
	p.What = Code;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Code + "*" );
	// Romanian	------------------
	// int
	Put ( "#GenderIntRo", GenderIntRo );
	Put ( "#SingularIntRo", SingularIntRo );
	Put ( "#PlurarIntRo", PlurarIntRo );
	// fract
	Put ( "#GenderFractionalRo", GenderFractionalRo );
	Put ( "#SingularFractionalRo", SingularFractionalRo );
	Put ( "#PlurarFractionalRo", PlurarFractionalRo );

	// English	------------------
	// int
	Put ( "#SingularIntEn", SingularIntEn );
	Put ( "#PlurarIntEn", PlurarIntEn );
	// fract
	Put ( "#SingularFractionalEn", SingularFractionalEn );
	Put ( "#PlurarFractionalEn", PlurarFractionalEn );

	Click ( "#FormWriteAndClose" );

EndProcedure

Procedure fillRu ( Code, GenderInt, NominativeInt, SingularInt, PlurarInt, GenderFractional, NominativeFractional, SingularFractional, PlurarFractional )

	With ( "Currencies" );
	p = Call ( "Common.Find.Params" );
	p.Where = "Code";
	p.What = Code;
	Call ( "Common.Find", p );
	Click ( "#ListContextMenuChange" );
	With ( Code + "*" );
	// int
	Put ( "#GenderIntRu", GenderInt );
	Put ( "#NominativeIntRu", NominativeInt );
	Put ( "#SingularIntRu", SingularInt );
	Put ( "#PlurarIntRu", PlurarInt );
	// fract
	Put ( "#GenderFractionalRu", GenderFractional );
	Put ( "#NominativeFractionalRu", NominativeFractional );
	Put ( "#SingularFractionalRu", SingularFractional );
	Put ( "#PlurarFractionalRu", PlurarFractional );

	Click ( "#FormWriteAndClose" );

EndProcedure

