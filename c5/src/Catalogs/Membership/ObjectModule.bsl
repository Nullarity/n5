#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
var SelectedUsers;
var Removing;
	
Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkAccess ()
		or not checkDoubles () ) then
		Cancel = true;
		return;
	endif;
	checkTenants ( CheckedAttributes );
	
EndProcedure

Function checkDoubles ()
	
	doubles = Collections.GetDoubles ( Tenants, "Tenant" );
	if ( doubles.Count () = 0 ) then
		return true;
	endif;
	for each row in doubles do
		Output.ValueDuplicated ( , Output.Row ( "Tenants", row.LineNumber, "Tenant" ) );
	enddo; 
	return false;
	
EndFunction

Function checkAccess ()

	if ( Tenants.Count () > 0
		and not TenantAccess.IsEmpty ()
		and TenantAccess <> PredefinedValue ( "Enum.Access.Undefined" ) ) then
		tenantFound = Tenants.FindRows ( new Structure ( "Tenant", SessionParameters.Tenant ) ).Count () > 0;
		wrongAccess = ( TenantAccess = PredefinedValue ( "Enum.Access.Allow" ) and not tenantFound )
			or ( TenantAccess = PredefinedValue ( "Enum.Access.Forbid" ) and tenantFound );
		if ( wrongAccess ) then
			Output.WrongMembershipTenantAccess ();
			return false;
		endif;
	endif;
	return true;
	
EndFunction

Procedure checkTenants ( CheckedAttributes )
	
	if ( TenantAccess <> Enums.Access.Undefined ) then
		CheckedAttributes.Add ( "Tenants" );
	endif;
	
EndProcedure

Procedure BeforeWrite ( Cancel )
	
	if ( Cloud.SaaS ()
		and Connections.IsDemo () ) then
		Output.DemoMode ();
		Cancel = true;
		return;
	endif;
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( deleting () ) then
		DeletionMark = Removing;
	else
		if ( formRequired () ) then
			Output.FormRequired ();
			Cancel = true;
		endif;
	endif;

EndProcedure

Function deleting ()
	
	Removing = undefined;
	if ( AdditionalProperties.Property ( Enum.AdditionalPropertiesRemoving (), Removing ) ) then
		return true;
	else
		return false;
	endif;
	
EndFunction

Function formRequired ()
	
	SelectedUsers = undefined;
	if ( AdditionalProperties.Property ( Enum.AdditionalPropertiesSelectedUsers (), SelectedUsers ) ) then
		return false;
	endif;
	if ( not IsNew ()
		and TenantAccess = Enums.Access.Allow
		and Tenants.Count () = 1
		and Tenants [ 0 ].Tenant = SessionParameters.Tenant ) then
		return false;
	endif;
	return true;
	
EndFunction

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( DeletionMark ) then
		if ( not Catalogs.Membership.Unpost ( Ref ) ) then
			Cancel = true;
		endif;
	else
		if ( not Catalogs.Membership.Post ( Ref, getSelectedUsers () ) ) then
			Cancel = true;
		endif;
	endif;

EndProcedure

Function getSelectedUsers ()
	
	if ( SelectedUsers = undefined ) then
		q = new Query ( "select User from InformationRegister.Membership where Membership = &Ref" );
		q.SetParameter ( "Ref", Ref );
		return q.Execute ().Unload ().UnloadColumn ( "User" );
	else
		return SelectedUsers;
	endif;
	
EndFunction

#endif
