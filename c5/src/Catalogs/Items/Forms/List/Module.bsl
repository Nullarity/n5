// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	UserTasks.InitList ( List );
	Options.SetAccuracy ( ThisObject, "Quantity", , false );
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer ( Settings )

	filterByWarehouse ();
	
EndProcedure

&AtServer
Procedure filterByWarehouse ()
	
	DC.ChangeFilter ( List, "Warehouse", WarehouseFilter, not WarehouseFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageBarcodeScanned ()
		and Source.FormOwner.UUID = ThisObject.UUID ) then
		showItem ( Parameter.Item );
	endif; 
	
EndProcedure

&AtClient
Procedure showItem ( Item )
	
	if ( Item = undefined ) then
		Output.BarcodeNotFound ();
	else
		Items.List.CurrentRow = Item;
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Scan ( Command )
	
	OpenForm ( "CommonForm.Scan", new Structure ( "JustScan", true ), ThisObject );
	
EndProcedure

&AtClient
Procedure WarehouseFilterOnChange ( Item )
	
	filterByWarehouse ();
	
EndProcedure

// *****************************************
// *********** List

&AtClient
Procedure ListSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	UserTasks.Click ( Item, SelectedRow, Field, StandardProcessing );
	
EndProcedure
