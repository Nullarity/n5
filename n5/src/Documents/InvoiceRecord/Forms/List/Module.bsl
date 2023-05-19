// *****************************************
// *********** Form events

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageInvoicesExchnage () ) then
		Items.List.Refresh ();
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CustomerFilterOnChange ( Item )
	
	filterByCustomer ();
	
EndProcedure

&AtClient
Procedure filterByCustomer ()
	
	DC.ChangeFilter ( List, "Customer", CustomerFilter, ValueIsFilled ( CustomerFilter ) );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "LoadingPoint", WarehouseFilter, ValueIsFilled ( WarehouseFilter ) );
	
EndProcedure

&AtClient
Procedure StatusFilterOnChange ( Item )
	
	filterByStatus ();
	
EndProcedure

&AtClient
Procedure filterByStatus ()
	
	DC.ChangeFilter ( List, "DocumentStatus", StatusFilter, not StatusFilter.IsEmpty () );
	
EndProcedure
