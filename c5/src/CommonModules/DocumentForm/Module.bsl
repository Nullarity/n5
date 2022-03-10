
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

Procedure CheckDate ( Form ) export
	
	date = objectDate ( Form );
	if ( date = Date ( 1, 1, 1 ) ) then
		return;
	endif;
	access = DocumentFormSrv.GetAccess ( Form.Object.Ref, date );
	if ( access.Allowed ) then
		hideRestrictions ( Form );
	else
		#if ( Server ) then
			showRestrictions ( Form, access );
		#else
			DocumentForm.OutputRestrictions ( access );
		#endif 
	endif;
	
EndProcedure

Function objectDate ( Form )	
	
	object = Form.Object;
	objectDate = object.Date;
	if ( objectDate = Date ( 1, 1, 1 ) ) then
		#if ( Server ) then
			if ( object.Ref.IsEmpty () ) then
				objectDate = CurrentSessionDate ();
			endif;
		#endif
	endif;
	return objectDate;
	
EndFunction

Procedure hideRestrictions ( Form )
	
	Form.Items.Access.Visible = false;
	
EndProcedure

&AtServer
Procedure showRestrictions ( Form, Access )
	
	prohibit = access.Action;
	msg = new Structure ( "User, Action", SessionParameters.User, prohibit );
	if ( prohibit = undefined ) then
		showAccessInfo ( Form, false, Output.RightsUndefined ( msg ) );
	else
		if ( prohibit = PredefinedValue ( "Enum.AccessRights.Any" ) ) then
			if ( access.Warning ) then
				showAccessInfo ( Form, true, Output.AnyModificationIsNotRecommended ( msg ) );
			else
				showAccessInfo ( Form, false, Output.AnyModificationIsNotAllowed ( msg ) );
			endif;
		else
			if ( access.Warning ) then
				showAccessInfo ( Form, true, Output.ModificationIsNotRecommended ( msg ) );
			else
				showAccessInfo ( Form, false, Output.ModificationIsNotAllowed ( msg ) );
			endif;
		endif; 
	endif; 
	
EndProcedure

Procedure showAccessInfo ( Form, Warning, Text )
	
	accessGroup = Form.Items.Access;
	accessGroup.Visible = true;
	content = accessGroup.ChildItems;
	content.AccessRightsDenial.Visible = not Warning;
	content.AccessRightsWarning.Visible = Warning;
	content.AccessRightsMessage.Title = Text;
		
EndProcedure

Procedure OutputRestrictions ( Access ) export
	
	prohibit = access.Action;
	msg = new Structure ( "User, Action", Logins.User (), prohibit );
	if ( prohibit = undefined ) then
		#if ( Server ) then
			Output.DocumentRightsUndefined ( msg );
		#else
			Output.DocumentRightsUndefined ( , , msg );
		#endif
	else
		if ( prohibit = PredefinedValue ( "Enum.AccessRights.Any" ) ) then
			#if ( Server ) then
				Output.DocumentAnyModificationIsNotAllowed ( msg );
			#else
				if ( access.Warning ) then
					Output.DocumentAnyModificationIsNotRecommended ( , , msg );
				else
					Output.DocumentAnyModificationIsNotAllowed ( , , msg );
				endif;
			#endif
		else
			#if ( Server ) then
				Output.DocumentModificationIsNotAllowed ( msg );
			#else
				if ( access.Warning ) then
					Output.DocumentModificationIsNotRecommended ( , , msg );
				else
					Output.DocumentModificationIsNotAllowed ( , , msg );
				endif;
			#endif
		endif; 
	endif; 
	
EndProcedure