#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Allowed ( Target ) export
	
	ok = Logins.Admin () or hasAccess ( Target );
	if ( ok ) then
		return true;
	endif; 
	Output.DocumentRightsPermissionError ( new Structure ( "Target", Target ) );
	return false;
	
EndFunction 

Function hasAccess ( Target )
	
	s = "
	|select top 1 1
	|from InformationRegister.RightsOwnership as RightsOwnership
	|where RightsOwnership.Owner = &User
	|and RightsOwnership.Target in (
	|	select &Target
	|	union all
	|	select User
	|	from InformationRegister.UsersAndGroups
	|	where UserGroup = &Target
	|)
	|";
	q = new Query ( s );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "Target", Target );
	return q.Execute ().Select ().Next ();
	
EndFunction 

#endif