// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure VendorFilterOnChange ( Item )
	
	filterByVendor ();
	
EndProcedure

&AtServer
Procedure filterByVendor ()
	
	DC.ChangeFilter ( List, "Vendor", VendorFilter, not VendorFilter.IsEmpty () );
	
EndProcedure 

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
