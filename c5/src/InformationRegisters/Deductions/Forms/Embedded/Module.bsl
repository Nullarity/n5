// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterByEmployee ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|ActualDeductions show ShowActual;
	|List show not ShowActual
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	employee = Parameters.Filter.Employee;
	DC.SetFilter ( UnusedDeductions, "Employee", employee );
	DC.SetFilter ( ActualDeductions, "Employee", employee );
	DC.SetFilter ( IncomeTax, "Individual", DF.Pick ( employee, "Individual" ) );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure ShowActual ( Command )
	
	toggleDeductions ();
	
EndProcedure

&AtClient
Procedure toggleDeductions ()
	
	ShowActual = not ShowActual;
	Appearance.Apply ( ThisObject, "ShowActual" );
	
EndProcedure 

&AtClient
Procedure ShowRecords ( Command )
	
	toggleDeductions ()

EndProcedure
