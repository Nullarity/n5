// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterWarehouses ();
	
EndProcedure

&AtServer
Procedure filterWarehouses ()
	
	company = undefined;
	Parameters.Filter.Property ( "Company", company );
	if ( ValueIsFilled ( company ) ) then
		filter = new Array ();
		filter.Add ( new ChoiceParameter ( "Filter.Owner", company ) );
		params = new FixedArray ( filter );
		Items.WorkshopFilter.ChoiceParameters = params;
		Items.WarehouseFilter.ChoiceParameters = params;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure WorkshopFilterOnChange ( Item )
	
	filterByVendor ();
	
EndProcedure

&AtClient
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", WorkshopFilter, not WorkshopFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure
