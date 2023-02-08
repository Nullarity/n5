// *****************************************
// *********** Group Form

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtServer
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Employees.Individual", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtServer
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Employees.Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	
EndProcedure 
