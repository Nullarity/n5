// *****************************************
// *********** Group Form

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtClient
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	
EndProcedure
