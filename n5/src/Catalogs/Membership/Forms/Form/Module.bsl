&AtClient
var IsNew;
&AtServer
var OldTenants;
&AtClient
var Syncing;
&AtClient
var ClosingRequested;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	loadObject ();
	
EndProcedure

&AtServer
Procedure loadObject ()
	
	readAccess ();
	RightsRelations = RightsTree.FillRights ( ThisObject );
	RightsConfirmed = true;
	fillUsers ();
	LimitedAccess = accessIsLimited ( Object.Ref );
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAccess ()
	
	Administrator = Logins.Admin ();
	Sysadmin = Logins.Sysadmin ();
	
EndProcedure 

&AtServer
Procedure fillUsers ()
	
	s = "
	|select Memberships.User as User
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Ref
	|order by Memberships.User.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Tables.Users.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtServer
Function accessIsLimited ( Ref ) export
	
	if ( Sysadmin ) then
		return false;
	elsif ( Administrator ) then
		s = "select allowed top 1 1
		|from Catalog.Membership.Tenants as Tenants
		|	//
		|	// Allowed Tenants
		|	//
		|	left join Catalog.Tenants as AllowedTenants
		|	on AllowedTenants.Ref = Tenants.Tenant
		|where Tenants.Ref = &Ref
		|and AllowedTenants.Ref is null
		|union all
		|select 1
		|from Catalog.Membership as Membership
		|where Membership.Ref = &Ref
		|and Membership.TenantAccess in (
		|	value ( Enum.Access.Undefined ),
		|	value ( Enum.Access.Forbid )
		|)";
		q = new Query ( s );
		q.SetParameter ( "Ref", Ref );
		return not q.Execute ().IsEmpty ();
	else
		return true;
	endif;
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		readAccess ();
		fillNew ();
		RightsRelations = RightsTree.FillRights ( ThisObject );
		RightsConfirmed = true;
	endif;
	initTenatsList ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		loadMembers ();
		if ( Sysadmin
			or not accessIsLimited ( Parameters.CopyingValue ) ) then
			return;
		endif;
	endif;
	tenants = Object.Tenants;
	tenants.Clear ();
	Object.TenantAccess = Enums.Access.Allow;
	row = tenants.Add ();
	row.Tenant = SessionParameters.Tenant;
	
EndProcedure

&AtServer
Procedure loadMembers ()
	
	s = "
	|select Memberships.User as User
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Membership
	|and not Memberships.User.DeletionMark";
	q = new Query ( s );
	q.SetParameter ( "Membership", Parameters.CopyingValue );
	Tables.Users.Load ( q.Execute ().Unload () );
	
EndProcedure

&AtServer
Procedure initTenatsList ()
	
	if ( Sysadmin ) then
		list = Items.TenantAccess.ChoiceList;
		list.Add ( Enums.Access.Undefined );
		list.Add ( Enums.Access.Allow );
		list.Add ( Enums.Access.Forbid );
	endif;
	
EndProcedure 

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|LimitedAccess show LimitedAccess;
	|TenantAccess show Sysadmin;
	|Tenants hide LimitedAccess or Object.TenantAccess = Enum.Access.Undefined;
	|Code Description Rights lock LimitedAccess;
	|MarkAll UnmarkAll disable LimitedAccess;
	|Rights enable Administrator;
	|MarkForDeletion show filled ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtClient
Procedure OnOpen ( Cancel )
	
	IsNew = Object.Ref.IsEmpty ();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkRights () ) then
		Cancel = true;
	endif; 
	
EndProcedure

&AtServer
Function checkRights ()
	
	if ( not RightsConfirmed ) then
		Output.ConfirmAccessRights ( , "RightsChanges", , "" );
		return false;
	endif;	
	error = not RightsTree.FillCheck ( ThisObject );
	if ( error ) then
		Output.SelectAccessRights ( , "Rights", , "" );
	endif; 
	return not error;
	
EndFunction

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( marking ( CurrentObject, WriteParameters ) ) then
		return;
	endif;
	if ( not CurrentObject.IsNew () ) then
		OldTenants = Catalogs.Membership.GetTenants ( Object.Ref );
	endif;
	cleanMembers ();
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	pushUsers ( CurrentObject );
	
EndProcedure

&AtServer
Function marking ( CurrentObject, WriteParameters )
	
	how = undefined;
	property = Enum.AdditionalPropertiesRemoving ();
	if ( WriteParameters.Property ( property, how ) ) then
		CurrentObject.AdditionalProperties.Insert ( property, how );
		return true;
	else
		return false;
	endif;

EndFunction

&AtServer
Procedure cleanMembers ()
	
	users = Tables.Users;
	i = users.Count ();
	while ( i > 0 ) do
		i = i - 1;
		if ( users [ i ].User.IsEmpty () ) then
			users.Delete ( i );
		endif;
	enddo;
	
EndProcedure

&AtServer
Procedure pushUsers ( CurrentObject )
	
	selectedUsers = Tables.Users.Unload ();
	selectedUsers.GroupBy ( "User" );
	users = selectedUsers.UnloadColumn ( "User" );
	CurrentObject.AdditionalProperties.Insert ( Enum.AdditionalPropertiesSelectedUsers (), users );
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )

	syncMembership ( CurrentObject );

EndProcedure

&AtServer
Procedure syncMembership ( CurrentObject )
	
	p = DataProcessors.SyncMembership.GetParams ();
	p.OldTenants = OldTenants;
	p.Membership = CurrentObject.Ref;
	args = new Array ();
	args.Add ( "SyncMembership" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Syncing = true;
	Progress.Open ( UUID, , new NotifyDescription ( "SyncingCompleted", ThisObject ), true );
	if ( IsNew ) then
		Notify ( Enum.MessageUserGroupCreated () );
		IsNew = false;
	endif; 
	Notify ( Enum.MessageUserGroupModified () );
	
EndProcedure

&AtClient
Procedure SyncingCompleted ( Result, Params ) export
	
	Syncing = undefined;
	if ( Result = false ) then
		return;
	endif;
	if ( ClosingRequested = true ) then
		Close ();
	endif;
	
EndProcedure

&AtClient
Procedure BeforeClose ( Cancel, Exit, WarningText, StandardProcessing )
	
	if ( Exit
		or Syncing = undefined ) then
		return;
	endif;
	Cancel = true;
	ClosingRequested = true;
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure MarkForDeletion ( Command )
	
	askUser ();
	
EndProcedure

&AtClient
Procedure askUser ()

	p = new Structure ( "Object", Object.Description );
	if ( DF.Pick ( Object.Ref, "DeletionMark" ) ) then
		Output.Undelete ( ThisObject, false, p, "DeletionMarkProcessing" ); 
	else
		Output.MarkForDeletion ( ThisObject, true, p, "DeletionMarkProcessing" ); 
	endif;

EndProcedure

&AtClient
Procedure DeletionMarkProcessing ( Answer, Delete ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	restoreObject ();
	Write ( new Structure ( Enum.AdditionalPropertiesRemoving (), Delete ) );
	
EndProcedure

&AtServer
Procedure restoreObject ()
	
	Modified = false;
	obj = Object.Ref.GetObject ();
	ValueToFormAttribute ( obj, "Object" );
	loadObject ();
	
EndProcedure

&AtClient
Procedure TenantAccessOnChange ( Item )

	clearTenants ();
	Appearance.Apply ( ThisObject, "Object.TenantAccess" );

EndProcedure

&AtClient
Procedure clearTenants ()
	
	if ( Object.TenantAccess = PredefinedValue ( "Enum.Access.Undefined" ) ) then
		Object.Tenants.Clear ();
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Rights

&AtClient
Procedure MarkAllRights ( Command )
	
	RightsTree.MarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure UnmarkAllRights ( Command )
	
	RightsTree.UnmarkAll ( Rights );
	
EndProcedure

&AtClient
Procedure ConfirmRights ( Command )
	
	RightsConfirmed = true;
	RightsTree.HideConfirmation ( ThisObject );	
	
EndProcedure

&AtClient
Procedure RevertRights ( Command )	
	
	RightsConfirmed = true;
	RightsTree.RevertRights ( ThisObject );
	
EndProcedure

&AtClient
Procedure Help ( Command )
	
	Output.RightsConfirmation ();
	
EndProcedure

&AtClient
Procedure RightsBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure RightsUseOnChange ( Item )
	
	if ( RightsTree.UseChanged ( ThisObject ) ) then
		showChanges ();	
		RightsTree.Expand ( ThisObject );
	endif;
	
EndProcedure

&AtServer
Procedure showChanges ()
	
	RightsConfirmed = false;
	RightsTree.FillChanges ( ThisObject );
	RightsTree.ShowConfirmation ( ThisObject );
	
EndProcedure
