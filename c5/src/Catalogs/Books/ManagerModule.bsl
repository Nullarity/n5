#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetSorting () export
	
	return Int ( CurrentUniversalDateInMilliseconds () / 1000 ) - 63545040000;
	
EndFunction 

Function CanChange ( Book ) export
	
	if ( Logins.Admin () ) then
		return true;
	endif; 
	s = "
	|select top 1 1
	|where &Ref in (
	|	select &Ref
	|	from InformationRegister.GroupsAccessBooks as GroupsAccess
	|		//
	|		// Groups
	|		//
	|		join InformationRegister.UsersAndGroupsDocuments as Groups
	|		on Groups.UserGroup = GroupsAccess.UserGroup
	|		and Groups.User = &CurrentUser
	|	where GroupsAccess.Write
	|	and GroupsAccess.Book in ( select AccessBook from InformationRegister.EffectiveRights where Book = &Ref )
	|	union
	|	select &Ref
	|	from InformationRegister.UsersAccessBooks as UsersAccess
	|	where UsersAccess.User = &CurrentUser
	|	and UsersAccess.Book in ( select AccessBook from InformationRegister.EffectiveRights where Book = &Ref )
	|	and UsersAccess.Write
	|	union
	|	select &Ref
	|	from InformationRegister.GroupsAccessBooks as GroupsAccess
	|	where GroupsAccess.UserGroup = value ( Catalog.UserGroupsDocuments.Everybody )
	|	and GroupsAccess.Book in ( select AccessBook from InformationRegister.EffectiveRights where Book = &Ref )
	|	and GroupsAccess.Write )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Book );
	q.SetParameter ( "CurrentUser", SessionParameters.User );
	return q.Execute ().Select ().Next ();
	
EndFunction 

#endif