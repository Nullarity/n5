StandardProcessing = false;

addVAT ( "Standard", "20" );
addVAT ( "Zero", , "0", "0%" );
addVAT ( "Reduced", "6" );
addVAT ( "Reduced", "8" );
addVAT ( "None", , "1", "Fără TVA" );

Procedure addVAT ( Type, Rate = undefined, Sort = undefined, Description = undefined )

	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.VAT" );
	With ( "VAT (cr*" );
	Put ( "#Type", Type );
	if ( Rate = undefined ) then
		Put ( "#Sorting", Sort );
		Put ( "#Description", Description );
	else
		Put ( "#Rate", Rate );
		Put ( "#Sorting", ? ( Sort = undefined, Rate, Sort ) );
	endif;
	Click ( "#FormWriteAndClose" );

EndProcedure
