// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	setDefault ();
	
EndProcedure

&AtServer
Procedure setDefault ()
	
	DefaultTemplate = Constants.Phone.Get () = Object.Ref;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveDefault ( CurrentObject );
	
EndProcedure

&AtServer
Procedure saveDefault ( CurrentObject )
	
	ref = CurrentObject.Ref;
	if ( DefaultTemplate ) then
		Constants.Phone.Set ( ref );
	elsif ( ref = Constants.Phone.Get () ) then
		Constants.Phone.Set ( undefined );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( Write () ) then
		Close ( Object.Mask );
	endif; 
	
EndProcedure

&AtClient
Procedure MaskOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = StrReplace ( Object.Mask, "\", "" );
	
EndProcedure 
