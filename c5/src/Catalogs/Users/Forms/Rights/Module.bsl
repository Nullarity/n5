// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	loadParams ();
	RightsRelations = RightsTree.GetRelations ();
	
EndProcedure

&AtServer
Procedure loadParams ()
	
	table = GetFromTempStorage ( Parameters.UserRights );
	ValueToFormData ( table, Rights );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Commit ( Command )
	
	Notify ( Enum.MessageUserRightsChanged (), rightsStorage () );
	Close ();
	
EndProcedure

&AtServer
Function rightsStorage ()
	
	return PutToTempStorage ( FormDataToValue ( Rights, Type ( "ValueTree" ) ), UUID );

EndFunction

// *****************************************
// *********** Table Rights

&AtClient
Procedure MarkAllRights ( Command )
	
	RightsTree.MarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure UnmarkAllRights ( Command )
	
	RightsTree.UnmarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure RightsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsUseOnChange ( Item )
	
	if ( RightsTree.UseChanged ( ThisObject ) ) then
		showChanges ();	
		RightsTree.Expand ( ThisObject );
	endif;
	
EndProcedure

&AtServer
Procedure showChanges ()
	
	RightsTree.FillChanges ( ThisObject );
	RightsTree.ShowConfirmation ( ThisObject );
	
EndProcedure

&AtClient
Procedure ConfirmRights ( Command )
	
	RightsTree.HideConfirmation ( ThisObject );	
	
EndProcedure

&AtClient
Procedure RevertRights ( Command )	
	
	RightsTree.RevertRights ( ThisObject );
	
EndProcedure

&AtClient
Procedure Help ( Command )
	
	Output.RightsConfirmation ();
	
EndProcedure
