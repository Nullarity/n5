Function Rooted () export
	
	return not SessionParameters.TenantUse
	and not InfoBaseUsers.CurrentUser ().DataSeparation.Property ( "Tenant" );
	
EndFunction 

Function Sysadmin () export
	
	return IsInRole ( "AdministratorSystem" );
	
EndFunction 

Function Admin () export
	
	return IsInRole ( "AdministratorSystem" )
	or IsInRole ( "Administrator" );
	
EndFunction 

Function Settings ( val Fields, val User = undefined ) export
	
	s = "
	|select top 1 " + Fields + "
	|from Catalog.UserSettings as UserSettings
	|where UserSettings.Owner = &User
	|";
	q = new Query ( s );
	q.SetParameter ( "User", ? ( User = undefined, SessionParameters.User, User ) );
	table = q.Execute ().Unload ();
	row = table [ 0 ];
	result = new Structure ();
	for each column in table.Columns do
		result.Insert ( column.Name, row [ column.Name ] );
	enddo; 
	return result;
	
EndFunction 

Function User () export
	
	return SessionParameters.User;
	
EndFunction
