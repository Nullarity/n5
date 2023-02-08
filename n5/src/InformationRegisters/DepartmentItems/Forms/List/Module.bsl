// *****************************************
// *********** Group Form

&AtClient
Procedure DepartmentFilterOnChange ( Item )
	
	filterByDepartment ();
	
EndProcedure

&AtServer
Procedure filterByDepartment ()
	
	DC.ChangeFilter ( List, "Department", DepartmentFilter, not DepartmentFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure ItemFilterOnChange ( Item )
	
	filterByItem ();
	
EndProcedure

&AtServer
Procedure filterByItem ()
	
	DC.ChangeFilter ( List, "Item", ItemFilter, not ItemFilter.IsEmpty () );
	
EndProcedure 
