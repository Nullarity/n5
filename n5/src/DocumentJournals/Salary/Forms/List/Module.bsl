// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	DC.SetParameter ( List, "Employee", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure 
