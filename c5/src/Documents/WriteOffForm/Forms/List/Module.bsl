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
Procedure ItemFilterOnChange ( Item )
	
	filterByItem ();
	
EndProcedure

&AtClient
Procedure filterByItem ()
	
	DC.ChangeFilter ( List, "Item", ItemFilter, not ItemFilter.IsEmpty () );
	
EndProcedure
