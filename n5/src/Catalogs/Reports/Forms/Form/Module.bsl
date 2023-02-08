// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		Father = Parameters.CopyingValue;
		fillNew ();
	endif; 
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	Object.Creator = SessionParameters.User;
	Object.Date = CurrentSessionDate ();
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.Ref.IsEmpty ()
		and not Father.IsEmpty () ) then
		inherit ( CurrentObject );
	endif; 
	
EndProcedure

&AtServer
Procedure inherit ( CurrentObject )
	
	CurrentObject.SetNewObjectRef ( Catalogs.Reports.GetRef ( new UUID () ) );
	ref = CurrentObject.GetNewObjectRef ();
	Catalogs.Reports.CopyInternals ( Father, CurrentObject );
	Catalogs.Reports.CopyFields ( Father, ref );
	
EndProcedure 
