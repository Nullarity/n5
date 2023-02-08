#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Errors export;
var Data;
var Password;
var OriginalTenant;
var OldTenants;

Procedure Exec () export
	
	init ();
	getData ();
	for each tenant in Catalogs.Users.GetTenants ( Parameters.User ) do
		activate ( tenant );
		update ( false );
		release ( tenant );
	enddo;
	if ( Errors.Count () = 0 ) then
		revoke ();
		activate ( OriginalTenant );
	else
		activate ( OriginalTenant );
		Progress.Put ( StrConcat ( Errors, Chars.LF ), JobKey, true );
	endif;

EndProcedure

Procedure init ()

	Errors = new Array ();
	OriginalTenant = SessionParameters.Tenant;
	OldTenants = Parameters.OldTenants;
	
EndProcedure

Procedure getData ()
	
	s = "
	|// @Fields
	|select Users.Description as Description, Users.Email as Email, Users.FirstName as FirstName,
	|	Users.FullName as FullName, Users.Gender as Gender, Users.LastName as LastName,
	|	Users.Patronymic as Patronymic, Users.TimeZone as TimeZone, Users.Login as Login, Users.Code as Code
	|from Catalog.Users as Users
	|where Users.Ref = &User
	|;
	|// #Membership
	|select Memberships.Membership as Ref, Memberships.Membership.TenantAccess as TenantAccess,
	|	Tenants.Tenant as Tenant
	|into Membership
	|from InformationRegister.Membership as Memberships
	|	//
	|	// Tenants
	|	//
	|	left join Catalog.Membership.Tenants as Tenants
	|	on Tenants.Ref = Memberships.Membership
	|	and not Tenants.Ref.DeletionMark
	|where Memberships.User = &User
	|;
	|// @Password
	|select Passwords.Password as Password
	|from InformationRegister.Passwords as Passwords
	|where Passwords.User = &User
	|";
	Data = SQL.Create ( s );
	Data.Q.SetParameter ( "User", Parameters.User );
	SQL.Perform ( Data );
	Password = ? ( Data.Password = undefined, undefined, Data.Password.Password );
	
EndProcedure

Procedure activate ( Tenant )
	
	try
		SessionParameters.Tenant = Tenant;
	except
		Progress.Put ( BriefErrorDescription ( ErrorInfo () ), JobKey, true );
		raise Output.OperationNotPerformed ();
	endtry;
	
EndProcedure

Procedure update ( RevokeAccess )
	
	ref = getUser ();
	newUser = ( ref = undefined );
	fields = Data.Fields;
	if ( newUser ) then
		obj = Catalogs.Users.CreateItem ();
		Metafields.Constructor ( obj );
		DF.SetNewCode ( obj, fields.Code );
	else
		obj = ref.GetObject ();
	endif;
	obj.AccessRevoked = RevokeAccess;
	FillPropertyValues ( obj, fields, , "Code" );
	determineAccess ( ref );
	properties = obj.AdditionalProperties;
	if ( Password <> undefined ) then
		properties.Insert ( Enum.AdditionalPropertiesPassword (), Password );
	endif;
	properties.Insert ( Enum.AdditionalPropertiesMembership (), Data.Groups.UnloadColumn ( "Ref" ) );
	BeginTransaction ();
	try
		obj.Write ();
	except
		error = BriefErrorDescription ( ErrorInfo () );
		RollbackTransaction ();
		addError ( error );
		return;
	endtry;
	if ( newUser ) then
		settings = Catalogs.UserSettings.CreateItem ();
		Catalogs.UserSettings.Init ( settings );
		settings.Owner = obj.Ref;
		try
			settings.Write ();
		except
			error = BriefErrorDescription ( ErrorInfo () );
			RollbackTransaction ();
			addError ( error );
			return;
		endtry;
	endif;
	CommitTransaction ();
	
EndProcedure

Function getUser ()
	
	s = "
	|select Users.Ref as Ref
	|from Catalog.Users as Users
	|where Users.Login = &Login";
	q = new Query ( s );
	q.SetParameter ( "Login", Data.Fields.Login );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction

Procedure determineAccess ( User )
	
	s = "
	|select Memberships.Membership as Ref, Memberships.Membership.TenantAccess as TenantAccess,
	|	Tenants.Tenant as Tenant
	|into LocalMembership
	|from InformationRegister.Membership as Memberships
	|	//
	|	// Tenants
	|	//
	|	left join Catalog.Membership.Tenants as Tenants
	|	on Tenants.Ref = Memberships.Membership
	|	and not Tenants.Ref.DeletionMark
	|where Memberships.User = &User
	|;
	|// #Groups
	|// LocalMembership
	|select LocalMembership.Ref as Ref
	|from LocalMembership as LocalMembership
	|where LocalMembership.Ref not in (
	|	select Ref as Ref from LocalMembership where TenantAccess = value ( Enum.Access.Undefined )
	|	union all
	|	select Ref from LocalMembership where TenantAccess = value ( Enum.Access.Allow ) and Tenant = &OriginalTenant
	|	union all
	|	select Ref from LocalMembership where TenantAccess = value ( Enum.Access.Forbid ) and Tenant <> &OriginalTenant
	|)
	|union
	|// CommonMembership
	|select Ref as Ref from Membership where TenantAccess = value ( Enum.Access.Undefined )
	|union all
	|select Ref from Membership where TenantAccess = value ( Enum.Access.Allow ) and Tenant = &Tenant
	|union all
	|select Ref from Membership where TenantAccess = value ( Enum.Access.Forbid ) and Tenant <> &Tenant
	|;
	|drop LocalMembership
	|";
	Data.Selection.Add ( s );
	Data.Q.SetParameter ( "User", User );
	Data.Q.SetParameter ( "Tenant", SessionParameters.Tenant );
	Data.Q.SetParameter ( "OriginalTenant", OriginalTenant );
	SQL.Perform ( Data );
	
EndProcedure

Procedure release ( Tenant )
	
	if ( OldTenants = undefined ) then
		return;
	endif;
	i = OldTenants.Find ( Tenant );
	if ( i <> undefined ) then
		OldTenants.Delete ( i );
	endif;

EndProcedure

Procedure addError ( Description )
	
	msg = new Structure ( "Tenant, Error", SessionParameters.Tenant, Description );
	Errors.Add ( Output.UserAccessChangingError ( msg ) );
	
EndProcedure

Procedure revoke ()
	
	if ( OldTenants = undefined ) then
		return;
	endif;
	for each tenant in OldTenants do
		activate ( tenant );
		update ( true );
	enddo;
	
EndProcedure

#endif
