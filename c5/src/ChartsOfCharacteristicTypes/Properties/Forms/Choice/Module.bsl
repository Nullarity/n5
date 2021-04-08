// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	setParameters ();

EndProcedure

&AtServer
Procedure setParameters ()
	
	owner = undefined;
	Parameters.Filter.Property ( "Owner", owner );
	DC.SetParameter ( List, "Owner", owner );
	scope = undefined;
	Parameters.Filter.Property ( "Scope", scope );
	DC.SetParameter ( List, "Scope", scope );
	
EndProcedure