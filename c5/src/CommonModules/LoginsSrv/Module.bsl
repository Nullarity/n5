Procedure ChangePassword ( User, Password ) export
	
	name = "" + User;
	ibuser = InfoBaseUsers.FindByName ( name );
	ibuser.Password = Password;
	ibuser.Write ();
	LoginsSrv.SavePassword ( User, Password );
	
EndProcedure 

Procedure SavePassword ( User, Password ) export
	
	r = InformationRegisters.Passwords.CreateRecordManager ();
	r.User = User;
	r.Password = Password;
	r.Write ();
	
EndProcedure 

Procedure ResetMustChangePassword () export
	
	obj = SessionParameters.Login.GetObject ();
	obj.MustChangePassword = false;
	obj.Write ();
	
EndProcedure 

Procedure SetRights ( User ) export
	
	SetPrivilegedMode ( true );
	roles = getUserRoles ( User.Name );
	assingRoles ( User, roles );
	
EndProcedure 

Function getUserRoles ( UserName )
	
	s = "
	|select Rights.RoleName as RoleName
	|from Catalog.Users.Rights as Rights
	|where Rights.Ref = &User
	|union
	|select Rights.RoleName
	|from Catalog.Membership.Rights as Rights
	|	//
	|	// Memberships
	|	//
	|	join InformationRegister.Membership as Memberships
	|	on Memberships.User = &User
	|	and Memberships.Membership = Rights.Ref
	|where not Rights.Ref.DeletionMark
	|";
	q = new Query ( s );
	user = Catalogs.Users.FindByDescription ( UserName, true );
	q.SetParameter ( "User", user );
	return q.Execute ().Unload ().UnloadColumn ( "RoleName" );
	
EndFunction 

Procedure assingRoles ( User, Roles )
	
	userRoles = User.Roles;
	appRoles = Metadata.Roles;
	wasUnlimited = userRoles.Contains ( appRoles.Unlimited );
	wasSysadmin = userRoles.Contains ( appRoles.AdministratorSystem );
	root = Logins.Sysadmin ();
	unlimited = Enum.SuperRolesUnlimited ();
	sysadmin = Enum.SuperRolesSysadmin ();
	userRoles.Clear ();
	userRoles.Add ( appRoles.User );
	for each roleName in Roles do
		role = appRoles.Find ( roleName );
		if ( role = undefined ) then
			apply = false;
		elsif ( root ) then
			apply = true;
		elsif ( roleName = unlimited
			and not wasUnlimited ) then
			apply = false;
		elsif ( roleName = sysadmin
			and not wasSysadmin ) then
			apply = false;
		else
			apply = true;
		endif;
		if ( apply ) then
			userRoles.Add ( role );
		endif;
	enddo; 
	
EndProcedure 

Procedure Remove ( UserName ) export
	
	user = InfoBaseUsers.FindByName ( UserName );
	if ( user = undefined ) then
		return;
	endif; 
	user.Delete ();
	
EndProcedure 

Function LastAdministrator () export
	
	if ( findAdmin () ) then
		return false;
	endif;
	Output.AdministratorNotFound ();
	return true;
	
EndFunction 

Function findAdmin ()
	
	s = "
	|select top 1 1
	|from Catalog.Users.Rights as Rights
	|where Rights.RoleName = ""Administrator""
	|and not Rights.Ref.DeletionMark
	|and not Rights.Ref.AccessDenied
	|and not Rights.Ref.AccessRevoked
	|union
	|select top 1 1
	|from Catalog.Membership.Rights as Rights
	|	//
	|	// Memberships
	|	//
	|	join InformationRegister.Membership as Memberships
	|	on Memberships.Membership = Rights.Ref
	|	and not Memberships.User.DeletionMark
	|	and not Memberships.User.AccessDenied
	|	and not Memberships.User.AccessRevoked
	|where Rights.RoleName = ""Administrator""
	|and not Rights.Ref.DeletionMark
	|";
	q = new Query ( s );
	found = not q.Execute ().IsEmpty ();
	return found;
	
EndFunction

Procedure SaveSettings ( ID, Class = undefined, Value ) export
	
	if ( AccessRight ( "SaveUserData", Metadata ) ) then
		CommonSettingsStorage.Save ( ID, Class, Value );
	endif; 
	
EndProcedure

Procedure DeleteSettings ( ID, Class = undefined ) export
	
	if ( AccessRight ( "SaveUserData", Metadata ) ) then
		CommonSettingsStorage.Delete ( ID, Class, String ( SessionParameters.User ) );
	endif; 
	
EndProcedure

Function Separated () export
	
	return Metadata.CommonAttributes.Tenant.UsersSeparation = Metadata.ObjectProperties.CommonAttributeUsersSeparation.Separate;
	
EndFunction