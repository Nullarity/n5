// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	PettyCashForm.Read ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	save ();
	Close ();
	
EndProcedure

&AtServer
Procedure save ()
	
	PettyCashForm.Save ( ThisObject );
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( Modified ) then
		Cancel = true;
		Output.ConfirmExit ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure ConfirmExit ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Cancel ) then
		return;
	elsif ( Answer = DialogReturnCode.No ) then
		Modified = false;
	else
		save ();
	endif; 
	Close ();
	
EndProcedure 

&AtClient
Procedure Write () export
	
	save ();
	
EndProcedure 