// *****************************************
// *********** Group Form

&AtClient
Procedure DepartmentFilterOnChange(Item)

	filterByDepartment ();
	
EndProcedure

&AtClient
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, ValueIsFilled ( DepartmentFilter ) );
	
EndProcedure

&AtClient
Procedure EmployeeFilterOnChange(Item)

	filterByEmployee ();
	
EndProcedure

&AtClient
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Employee", EmployeeFilter, ValueIsFilled ( EmployeeFilter ) );
	
EndProcedure
