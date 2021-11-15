Connect ();
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.DeductionsClassifier" );

add ( "P", "24000" );
add ( "H", "18000" );
add ( "M", "18000" );
add ( "N", "3000" );
add ( "S", "11280" );
add ( "Sm", "30000" );

Procedure add ( Deduction, AnnualAmount )

	date = "10/01/2018";

	With ( "Deductions" );
	Click ( "#FormCreate" );
	form = With ( "Deductions (create)" );
	Put ( "#Code", Deduction );
	Put ( "#Description", Deduction );
	Click ( "#Write" );
	Click ( "#RatesContextMenuCreate" );
	With ( "Deduction Rates (create)" );
	Put ( "#Period", date );
	Put ( "#Rate", AnnualAmount );
	Click ( "#FormWriteAndClose" );
	Close ( form );

EndProcedure


