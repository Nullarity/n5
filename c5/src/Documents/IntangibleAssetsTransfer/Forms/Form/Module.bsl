// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	AssetsTransferForm.OnCreateAtServer ( ThisObject );
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

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
