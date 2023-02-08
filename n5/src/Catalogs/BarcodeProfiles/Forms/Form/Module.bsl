// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	restoreTemplate ( CurrentObject );
	
EndProcedure

&AtServer
Procedure restoreTemplate ( CurrentObject )
	
	TabDoc = CurrentObject.Template.Get ();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	saveTemplate ( CurrentObject );
	
EndProcedure

&AtServer
Procedure saveTemplate ( CurrentObject )
	
	CurrentObject.Template = new ValueStorage ( TabDoc );
	
EndProcedure
