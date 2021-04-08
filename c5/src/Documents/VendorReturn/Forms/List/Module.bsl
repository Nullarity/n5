// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	InvoiceForm.SetPaidPercent ( ThisObject );
	UserTasks.InitList ( List );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.InvoiceRecordsWrite () ) then
		base = Source.Base;
		if ( TypeOf ( base ) = Type ( "DocumentRef.VendorReturn" ) ) then
			NotifyChanged ( base );
		endif;
	endif; 
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure VendorFilterOnChange ( Item )
	
	filterByVendor ();
	
EndProcedure

&AtClient
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", VendorFilter, ValueIsFilled ( VendorFilter ) );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

&AtClient
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, ValueIsFilled ( WarehouseFilter ) );
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure