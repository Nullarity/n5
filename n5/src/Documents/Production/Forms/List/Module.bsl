// *****************************************
// *********** Group Form

&AtClient
Procedure WorkshopFilterOnChange ( Item )
	
	filterByWorkshop ();
	
EndProcedure

&AtClient
Procedure filterByWorkshop ()
	
	DC.ChangeFilter ( List, "Workshop", WorkshopFilter, not WorkshopFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure
