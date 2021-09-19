// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	init ();
	filterByCompany ();

EndProcedure

&AtServer
Procedure init ()
	
	UnitFilter = Logins.Settings ( "Company" ).Company;
	
EndProcedure

&AtServer
Procedure filterByCompany ()
	
	DC.ChangeFilter ( List, "Owner", UnitFilter, ValueIsFilled ( UnitFilter ) );
	
EndProcedure

&AtClient
Procedure UnitFilterOnChange ( Item )

	filterByCompany ();

EndProcedure
