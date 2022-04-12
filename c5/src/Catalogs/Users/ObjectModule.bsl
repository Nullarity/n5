#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var IsNew;
var CurrentName;
var OldTenants;
var Removing;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( IsFolder ) then
		return;
	endif; 
	if ( not checkEmail () ) then
		Cancel = true;
	endif; 
	if ( not checkUserClass () ) then
		Cancel = true;
	endif; 
	checkCompanyAccess ( CheckedAttributes );
	checkOrganizationAccess ( CheckedAttributes );
	checkWarehouseAccess ( CheckedAttributes );
	
EndProcedure

Function checkEmail ()
	
	result = Mailboxes.TestAddress ( Email );
	if ( not result ) then
		Output.InvalidEmail ( , "Email" );
	endif; 
	return result;
	
EndFunction 

Function checkUserClass ()
	
	if ( UserClass = Enums.Users.Customer
		and OrganizationAccess = Enums.Access.Undefined ) then
		Output.OrganizationAccessMustBeInstalled ( , "OrganizationAccess" );
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure checkCompanyAccess ( CheckedAttributes )
	
	if ( CompanyAccess = Enums.Access.Allow
		or CompanyAccess = Enums.Access.Forbid ) then
		CheckedAttributes.Add ( "Companies" );
	endif; 
	
EndProcedure 

Procedure checkOrganizationAccess ( CheckedAttributes )
	
	if ( OrganizationAccess = Enums.Access.Allow
		or OrganizationAccess = Enums.Access.Forbid ) then
		CheckedAttributes.Add ( "Organizations" );
	elsif ( OrganizationAccess = Enums.Access.States ) then
		CheckedAttributes.Add ( "OrganizationsStates" );
	endif; 
	
EndProcedure 

Procedure checkWarehouseAccess ( CheckedAttributes )
	
	if ( WarehouseAccess = Enums.Access.Allow
		or WarehouseAccess = Enums.Access.Forbid ) then
		CheckedAttributes.Add ( "Warehouses" );
	elsif ( WarehouseAccess = Enums.Access.States ) then
		CheckedAttributes.Add ( "WarehousesStates" );
	endif; 
	
EndProcedure 

Procedure BeforeWrite ( Cancel )

	if ( Cloud.SaaS ()
		and Connections.IsDemo () ) then
		Output.DemoMode ();
		Cancel = true;
		return;
	endif; 
	if ( DataExchange.Load
		or IsFolder ) then
		return;
	endif;
	IsNew = IsNew ();
	getCurrentName ();
	if ( not IsNew
		and DF.Pick ( Ref, "DeletionMark" ) <> DeletionMark ) then
		SetPrivilegedMode ( true );
		mark ( Catalogs.Mailboxes );
		mark ( Catalogs.UserSettings );
		markSession ( DeletionMark );
		disableRLS ();
		return;
	endif;
	
EndProcedure

Procedure getCurrentName ()
	
	if ( IsNew ) then
		CurrentName = Description;
	else
		CurrentName = DF.Pick ( Ref, "Description" );
	endif; 
	
EndProcedure 

Procedure mark ( Class )
	
	selection = Class.Select ( , Ref );
	while ( selection.Next () ) do
		if ( selection.DeletionMark <> DeletionMark ) then
			selection.GetObject ().SetDeletionMark ( DeletionMark );
		endif;
	enddo;

EndProcedure

Procedure markSession ( Mark )

	for each session in userSessions ( Mark ) do
		session.GetObject ().SetDeletionMark ( Mark );
	enddo;	
	
EndProcedure

Function userSessions ( Mark )

	s = "
	|select Sessions.Ref as Ref
	|from Catalog.Sessions as Sessions
	|where Sessions.User = &Ref
	|and Sessions.DeletionMark <> &Mark";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Mark", Mark );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );

EndFunction

Procedure disableRLS ()
	
	Removing = true;
	DataExchange.Load = true;

EndProcedure

Procedure OnWrite ( Cancel )
	
	skip = IsFolder or ( DataExchange.Load and not Removing );
	if ( skip ) then
		return;
	endif;
	SetPrivilegedMode ( true );
	if ( DeletionMark ) then
		LoginsSrv.Remove ( CurrentName );
	else
		makeAccess ();
		makeProfile ();
		if ( IsNew ) then
			setInterface ();
		endif;
	endif;
	if ( LoginsSrv.LastAdministrator () ) then
		Cancel = true;
		return;
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure makeAccess ()
	
	groups = undefined;
	if ( not AdditionalProperties.Property ( Enum.AdditionalPropertiesMembership (), groups ) ) then
		return;
	endif; 
	recordset = InformationRegisters.Membership.CreateRecordSet ();
	recordset.Filter.User.Set ( Ref );
	for each membership in groups do
		movement = recordset.Add ();
		movement.Membership = membership;
		movement.User = Ref;
	enddo; 
	recordset.Write ();
	
EndProcedure 

Procedure makeProfile ()
	
	user = getIBUser ();
	setProfile ( user );
	setOptions ( user );
	LoginsSrv.SetRights ( user );
	user.Write ();
	
EndProcedure 

Function getIBUser ()
	
	user = InfoBaseUsers.FindByName ( CurrentName );
	if ( user = undefined ) then
		user = InfoBaseUsers.CreateUser ();
	endif;
	return user;
	
EndFunction

Procedure setProfile ( User )
	
	User.Name = Description;
	User.FullName = FullName;
	User.ShowInList = Show;
	User.UnsafeOperationProtection.UnsafeOperationWarnings = Protection;
	if ( OSAuth ) then
		User.OSAuthentication = true; 
		User.OSUser = OSUser;
	else 
		User.OSAuthentication = false; 
		User.OSUser = undefined;
	endif;
	if ( LoginsSrv.Separated () ) then
		User.DataSeparation.Insert ( "Tenant", DF.Pick ( SessionParameters.Tenant, "Code" ) );
	endif;
	User.Language = Metadata.Languages.Find ( Language );
	password = undefined;
	if ( AdditionalProperties.Property ( Enum.AdditionalPropertiesPassword (), password ) ) then
		User.Password = password;
		LoginsSrv.SavePassword ( Ref, password );
	endif; 
	
EndProcedure

Procedure setOptions ( User )

	r = InformationRegisters.UserOptions.CreateRecordManager ();	
	r.User = Ref;
	if ( User.Language = Metadata.Languages.Russian ) then
		r.Romanian = false;
		r.Russian = true;
	else
		r.Romanian = true;
		r.Russian = false;
	endif;
	r.Write ();
	
EndProcedure 
 
Procedure setInterface ()
	
	settings = new ClientSettings ();
	settings.ShowNavigationAndActionsPanels = false;
	settings.ApplicationFormsOpenningMode = ApplicationFormsOpenningMode.Tabs;
	SystemSettingsStorage.Save ( "Common/ClientSettings", "", settings, , Description );
	settings = new CommandInterfaceSettings ();
	settings.SectionsPanelRepresentation = SectionsPanelRepresentation.Picture;
	SystemSettingsStorage.Save ( "Common/SectionsPanel/CommandInterfaceSettings", "", settings, , Description );
	
EndProcedure 

// *****************************************
// *********** Variables Initialization

Removing = false;

#endif