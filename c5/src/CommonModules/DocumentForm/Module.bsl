
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