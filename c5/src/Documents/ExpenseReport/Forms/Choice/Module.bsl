
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setFilters ();
	
EndProcedure

&AtServer
Procedure setFilters ()
	
	company = undefined;
	Parameters.Filter.Property ( "Company", company );
	if ( ValueIsFilled ( company ) ) then
		filter = new Array ();
		filter.Add ( new ChoiceParameter ( "Filter.Owner", company ) );
		Items.WarehouseFilter.ChoiceParameters = new FixedArray ( filter );
		filter = new Array ();
		filter.Add ( new ChoiceParameter ( "Filter.Company", company ) );
		Items.EmployeeFilter.ChoiceParameters = new FixedArray ( filter );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure EmployeeFilterOnChange ( Item )
	
	filterByEmployee ();
	
EndProcedure

&AtClient
Procedure filterByEmployee ()
	
	DC.ChangeFilter ( List, "Employee", EmployeeFilter, not EmployeeFilter.IsEmpty () );
	
EndProcedure
