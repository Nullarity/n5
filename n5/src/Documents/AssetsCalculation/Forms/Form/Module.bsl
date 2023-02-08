
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		updateChangesPermission ();
	endif; 
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	DocumentForm.Init ( Object );
	setDate ( CurrentSessionDate () );
	
EndProcedure

&AtServer
Procedure setDate ( Date ) 

	Object.Date = EndOfMonth ( Date );

EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	applyDate ();
	
EndProcedure

&AtServer
Procedure applyDate ()
	
	date = Object.Date;
	setDate ( date );
	Documents.AssetsCalculation.CheckDate ( Object.Ref, date );
	updateChangesPermission ();

EndProcedure
