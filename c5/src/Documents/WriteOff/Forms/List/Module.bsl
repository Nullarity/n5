
// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )

	if ( EventName = Enum.InvoiceRecordsWrite () ) then
		base = Source.Base;
		if ( TypeOf ( base ) = Type ( "DocumentRef.WriteOff" ) ) then
			NotifyChanged ( base );
		endif;
	elsif ( EventName = Enum.MessageInvoicesExchnage () ) then
		Items.List.Refresh ();
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

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
