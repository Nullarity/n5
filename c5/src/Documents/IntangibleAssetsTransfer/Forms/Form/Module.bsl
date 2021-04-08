// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	AssetsTransferForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure CompanyOnChange ( Item )
	
	Options.ApplyCompany ( ThisObject );
	
EndProcedure

&AtClient
Procedure SenderOnChange ( Item )
	
	FillTable ();
	
EndProcedure

&AtServer
Procedure FillTable () export
	
	AssetsTransferForm.FillTable ( Object );
	
EndProcedure 

&AtClient
Procedure ResponsibleOnChange ( Item )
	
	FillTable ();
	
EndProcedure

// *****************************************
// *********** Table Items

&AtClient
Procedure Fill ( Command )
	
	AssetsTransferForm.Fill ( ThisObject );
	
EndProcedure
