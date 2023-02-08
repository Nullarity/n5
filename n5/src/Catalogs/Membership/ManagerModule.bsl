#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetTenants ( Membership ) export
	
	s = "
	|select allowed Memberships.TenantAccess as Access, List.Tenant as Tenant
	|into Memberships
	|from Catalog.Membership as Memberships
	|	//
	|	// Tenants List
	|	//
	|	left join Catalog.Membership.Tenants as List
	|	on List.Ref = Memberships.Ref
	|where Memberships.Ref = &Ref
	|;
	|select allowed Tenants.Ref as Tenant
	|from Catalog.Tenants as Tenants
	|where not Tenants.DeletionMark
	|and Tenants.Ref <> &Tenant
	|and value ( Enum.Access.Undefined ) in ( select top 1 Access from Memberships )
	|union
	|select Tenants.Ref
	|from Catalog.Tenants as Tenants
	|where not Tenants.DeletionMark
	|and Tenants.Ref <> &Tenant
	|and ( value ( Enum.Access.Allow ), Tenants.Ref ) in (
	|	select Access, Tenant
	|	from Memberships
	|)
	|union
	|select Tenants.Ref
	|from Catalog.Tenants as Tenants
	|where value ( Enum.Access.Forbid ) in ( select top 1 Access from Memberships )
	|and Tenants.Ref not in ( select Tenant from Memberships union all select &Tenant )
	|and not Tenants.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Membership );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	return q.Execute ().Unload ().UnloadColumn ( "Tenant" );
	
EndFunction

Function Post ( Ref, SelectedUsers ) export

	SetPrivilegedMode ( true );
	dismissed = dismissedUsers ( Ref, SelectedUsers );  
	makeMembership ( Ref, SelectedUsers );
	if ( LoginsSrv.LastAdministrator () ) then
		return false;
	endif;
	setRights ( dismissed );
	grantAccess ( Ref );
	SetPrivilegedMode ( false );
	return true;

EndFunction

Function dismissedUsers ( Ref, SelectedUsers )
	
	s = "
	|select Memberships.User.Description as Name
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Ref
	|and Memberships.User not in ( &Users )
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Users", SelectedUsers );
	return q.Execute ().Unload ().UnloadColumn ( "Name" );
	
EndFunction

Procedure makeMembership ( Ref, SelectedUsers )
	
	recordset = InformationRegisters.Membership.CreateRecordSet ();
	recordset.Filter.Membership.Set ( Ref );
	for each user in SelectedUsers do
		movement = recordset.Add ();
		movement.Membership = Ref;
		movement.User = user;
	enddo; 
	recordset.Write ();
	
EndProcedure

Procedure setRights ( Users )
	
	for each name in Users do
		user = InfoBaseUsers.FindByName ( name );
		if ( user = undefined ) then
			continue;
		endif; 
		LoginsSrv.SetRights ( user );
		user.Write ();
	enddo; 
	
EndProcedure 

Procedure grantAccess ( Ref )
	
	s = "
	|select Memberships.User.Description as Name
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	setRights ( q.Execute ().Unload ().UnloadColumn ( "Name" ) );
	
EndProcedure

Function Unpost ( Ref ) export

	SetPrivilegedMode ( true );
	dismissed = membershipUsers ( Ref );  
	revokeMembership ( Ref );
	if ( LoginsSrv.LastAdministrator () ) then
		return false;
	endif;
	setRights ( dismissed );
	SetPrivilegedMode ( false );
	return true;

EndFunction

Function membershipUsers ( Ref )
	
	s = "
	|select Memberships.User.Description as Name
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Name" );
	
EndFunction

Procedure revokeMembership ( Ref )
	
	recordset = InformationRegisters.Membership.CreateRecordSet ();
	recordset.Filter.Membership.Set ( Ref );
	recordset.Write ();
	
EndProcedure

#endif