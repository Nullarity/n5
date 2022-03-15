&AtClient
var ItemsRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	InventoryAssetsForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure NewWriteProcessing ( NewObject, Source, StandardProcessing )
	
	setLinks ();
	
EndProcedure

&AtServer
Procedure setLinks ()
	
	InventoryAssetsForm.SetLinks ( ThisObject );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );
	InventoryAssetsForm.BeforeWrite ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Fill ( Command )
	
	InventoryAssetsForm.Fill ( ThisObject );
	
EndProcedure

&AtServer
Procedure FillTable () export
	
	InventoryAssetsFormSrv.Fill ( ThisObject );
	
EndProcedure 

&AtClient
Procedure ItemsOnActivateRow ( Item )
	
	ItemsRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure ItemsOnEditEnd ( Item, NewRow, CancelEdit )
	
	InventoryAssetsForm.CalcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAfterDeleteRow ( Item )
	
	InventoryAssetsForm.CalcTotals ( Object );
	
EndProcedure

&AtClient
Procedure ItemsAvailabilityOnChange ( Item )
	
	InventoryAssetsForm.CalcDifference ( ItemsRow );
	
EndProcedure

&AtClient
Procedure ItemsAmountOnChange ( Item )
	
	InventoryAssetsForm.CalcDifference ( ItemsRow );
	
EndProcedure
