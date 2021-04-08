
Procedure Init ( Object ) export
	
	DocumentForm.SetCreator ( Object );
	setDate ( object );
	
EndProcedure 

Procedure SetCreator ( Object ) export
	
	Object.Creator = SessionParameters.User;
	
EndProcedure 

Procedure setDate ( Object )
	
	value = CommonSettingsStorage.Load ( Enum.SettingsPinnedDate (), TypeOf ( Object.Ref ) );
	if ( value <> undefined ) then
		Object.Date = value;
	endif; 
	
EndProcedure 
