
addPhone ( "(999) 999-9999" );
addPhone ( "(999) 999-99-99" );
addPhone ( "9-999-999-9999" );
addPhone ( "+999 (99) 999999" );
addPhone ( "+999 99 999 99 99" );
addPhone ( "(999) 999-9999, ext.9999" );

// *************************
// Procedures
// *************************

Procedure addPhone ( Mask )

	Commando ( "e1cib/data/Catalog.Phones" );
	With ( "Phone Numbers (create)" );
	Put ( "#Mask", Mask );
	Put ( "#Description", Mask );
	Click ( "#FormOK" );

EndProcedure
