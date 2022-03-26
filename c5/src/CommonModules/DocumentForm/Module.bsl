
&AtServer
Procedure Init ( Object ) export
	
	DocumentForm.SetCreator ( Object );
	setDate ( object );
	
EndProcedure 

&AtServer
Procedure SetCreator ( Object ) export
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure setDate ( Object )
	
	value = CommonSettingsStorage.Load ( Enum.SettingsPinnedDate (), TypeOf ( Object.Ref ) );
	if ( value <> undefined ) then
		Object.Date = value;
	endif; 
	
EndProcedure 

&AtClient
Function SaveNew ( Form ) export
	
	if ( Form.Object.Ref.IsEmpty () ) then
		return form.Write ( new Structure ( Enum.WriteParametersJustSave (), true ) );
	else
		return true;
	endif;

EndFunction

Function Closing ( WriteParameters ) export
	
	var action;
	if ( not WriteParameters.Property ( Enum.AdditionalPropertiesUserAction (), action ) ) then
		return false;
	endif;
	return action = Enum.DocumentActionsPostAndClose ()
	or action = Enum.DocumentActionsPostAndNew ()
	or action = Enum.DocumentActionsSaveAndNew ();

EndFunction
