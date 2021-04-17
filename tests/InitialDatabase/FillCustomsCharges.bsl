StandardProcessing = false;

add ( "Customs Procedures, 010", "Плата за таможенные процедуры, 010" );
add ( "Customs Duty, 020", "Таможенная пошлина, 020" );
add ( "Other Customs Duties, 027", "Прочие таможенные платежи, 027" );
add ( "Excise, 028", "Акциз, 028" );
add ( "VAT, 030", "НДС, 030", true );
add ( "Special Duty, 035", "Специальная пошлина, 035" );

Procedure add ( Name, NameRu, VAT = false )

	Commando ( "e1cib/Data/Catalog.CustomsCharges" );
	With ( "Customs Charges (create)" );
	Put ( "#Type", Name );
	Put ( "#Description", NameRu );
	if ( VAT ) then
		Put ( "#VAT", "20%" );
	endif;

	Click ( "#FormWriteAndClose" );

EndProcedure


