// *****************************************
// *********** Group Form

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtClient
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, ValueIsFilled ( DepartmentFilter ) );
	
EndProcedure
