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

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure
