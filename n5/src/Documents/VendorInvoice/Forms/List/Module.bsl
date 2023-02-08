// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	InvoiceForm.SetPaidPercent ( ThisObject );
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure VendorFilterOnChange ( Item )
	
	filterByVendor ();
	
EndProcedure

&AtClient
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", VendorFilter, not VendorFilter.IsEmpty () );
	
EndProcedure

&AtClient
Procedure ManagerFilterOnChange ( Item )
	
	filterByManager ();
	
EndProcedure

&AtClient
Procedure filterByManager ()
	
	DC.ChangeFilter ( List, "Manager", ManagerFilter, not ManagerFilter.IsEmpty () );
	
EndProcedure

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
