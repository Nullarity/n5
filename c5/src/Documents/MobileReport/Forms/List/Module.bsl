// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtClient
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Employee", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure
