#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FormGetProcessing ( FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing )

	if ( FormType = "ObjectForm" ) then
		if ( accessRestricted ( Parameters ) ) then
			StandardProcessing = false;
			SelectedForm = Metadata.Catalogs.Users.Forms.Readonly;
		endif;
	endif;

EndProcedure

Function accessRestricted ( Parameters )
	
	restricted = Parameters.Property ( "Key" )
	and Parameters.Key <> SessionParameters.User
	and not AccessRight ( "Edit", Metadata.Catalogs.Users );
	return restricted;

EndFunction

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "FullName" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Data.FullName;
	
EndProcedure

Function GetTenants ( User ) export
	
	s = "
	|select allowed Logins.TenantAccess as Access, List.Tenant as Tenant
	|into LoginTenants
	|from Catalog.Logins as Logins
	|	//
	|	// Tenants List
	|	//
	|	left join Catalog.Logins.Tenants as List
	|	on List.Ref = Logins.Ref
	|where Logins.Ref in ( select Login from Catalog.Users where Ref = &Ref )
	|;
	|select allowed Tenants.Ref as Tenant
	|from Catalog.Tenants as Tenants
	|where not Tenants.DeletionMark
	|and Tenants.Ref <> &Tenant
	|and value ( Enum.Access.Undefined ) in ( select top 1 Access from LoginTenants )
	|union
	|select Tenants.Ref
	|from Catalog.Tenants as Tenants
	|where not Tenants.DeletionMark
	|and Tenants.Ref <> &Tenant
	|and ( value ( Enum.Access.Allow ), Tenants.Ref ) in (
	|	select Access, Tenant
	|	from LoginTenants
	|)
	|union
	|select Tenants.Ref
	|from Catalog.Tenants as Tenants
	|where value ( Enum.Access.Forbid ) in ( select top 1 Access from LoginTenants )
	|and Tenants.Ref not in ( select Tenant from LoginTenants union all select &Tenant )
	|and not Tenants.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", User );
	q.SetParameter ( "Tenant", SessionParameters.Tenant );
	return q.Execute ().Unload ().UnloadColumn ( "Tenant" );
	
EndFunction

#endif
