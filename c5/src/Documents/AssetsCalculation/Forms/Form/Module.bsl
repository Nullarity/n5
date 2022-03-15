
// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
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
	setDate ( Object, CurrentDate () );
	
EndProcedure

&AtClientAtServerNoContext
Procedure setDate ( Object, Date ) 

	Object.Date = EndOfMonth ( Date );

EndProcedure

&AtClient
Procedure BeforeWrite ( Cancel, WriteParameters )
	
	StandardButtons.AdjustSaving ( ThisObject, WriteParameters );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )
	
	date = Object.Date;
	setDate ( Object, date );
	checkDate ( Object.Ref, date );
	
EndProcedure

&AtServerNoContext
Function checkDate ( Ref, Date )
	
	return Documents.AssetsCalculation.CheckDate ( Ref, Date );
	
EndFunction
