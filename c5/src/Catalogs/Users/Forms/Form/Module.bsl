&AtServer
var Copy;
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
	
	readAccess ();
	ref = Object.Ref;
	readSettings ( ref );
	loginRef = Object.Login;
	readLogin ( loginRef );
	LimitedAccess = accessIsLimited ( loginRef );
	RightsTree.FillRights ( ThisObject );
	fillMemberships ( ref );
	fillActualRights ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAccess ()
	
	Administrator = Logins.Admin ();
	Sysadmin = Logins.Sysadmin ();
	
EndProcedure 

&AtServer
Procedure readSettings ( User )
	
	settings = Logins.Settings ( "Ref", User );
	obj = settings.Ref.GetObject ();
	ref = Object.Ref;
	copying = ( User <> ref ); 
	if ( copying ) then
		obj = obj.Copy ();
		obj.Owner = undefined;
	endif;
	ValueToFormAttribute ( obj, "UserSettings" );
	MyProfile = not Logins.Rooted () and ( ref = SessionParameters.User );
	
EndProcedure

&AtServer
Procedure readLogin ( Login )
	
	obj = Login.GetObject ();
	ref = Object.Login;
	copying = ( Login <> ref ); 
	if ( copying ) then
		obj = obj.Copy ();
	endif;
	ValueToFormAttribute ( obj, "Login" );
	
EndProcedure

&AtServer
Function accessIsLimited ( Ref )
	
	if ( Sysadmin ) then
		return false;
	elsif ( Administrator ) then
		s = "select allowed top 1 1
		|from Catalog.Logins.Tenants as Tenants
		|	//
		|	// Allowed Tenants
		|	//
		|	left join Catalog.Tenants as AllowedTenants
		|	on AllowedTenants.Ref = Tenants.Tenant
		|where Tenants.Ref = &Ref
		|and AllowedTenants.Ref is null
		|union all
		|select 1
		|from Catalog.Logins as Logins
		|where Logins.Ref = &Ref
		|and Logins.TenantAccess in (
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
Procedure fillMemberships ( User )
	
	s = "select allowed Memberships.Ref as Membership,
	|	case when SelectedGroups.Membership is null then false else true end as Use
	|from Catalog.Membership as Memberships
	|	//
	|	// SelectedGroups
	|	//
	|	left join InformationRegister.Membership as SelectedGroups
	|	on SelectedGroups.Membership = Memberships.Ref
	|	and SelectedGroups.User = &Ref
	|where not Memberships.DeletionMark
	|order by Memberships.Ref.Description
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", User );
	Tables.Membership.Load ( q.Execute ().Unload () );
	
EndProcedure 

&AtServer
Procedure fillActualRights ()
	
	env = RightsTree.GetEnv ( ThisObject );
	RightsTree.PrepareRightsTable ( env );
	getSelectedRights ( env );
	addRolesToArray ( env );
	fillRightsByGroups ( env, Tables.Membership.Unload () );
	RightsTree.FillRightsTable ( env );
	RightsTree.SetCheckboxesForGroups ( Env.RightsTable.Rows );
	deleteUnusedRows ( Env.RightsTable.Rows );
	ValueToFormAttribute ( Env.RightsTable, "ActualAccess" );
	
EndProcedure

&AtServer
Procedure getSelectedRights ( Env )
	
	Env.Insert ( "SelectedRights", new Array () );
	
EndProcedure 

&AtServer
Procedure addRolesToArray ( Env )
	
	rightsValueTree = FormDataToValue ( Env.Form.Rights, Type ( "ValueTree" ) );
	list = Env.SelectedRights;
	for each groupRow in rightsValueTree.Rows do
		if ( groupRow.Use = 0 ) then
			continue;
		endif;
		for each row in groupRow.Rows do
			if ( row.Use = 1 ) then
				list.Add ( row.roleName );
			endif;
		enddo;
	enddo;	
		
EndProcedure

&AtServer
Procedure deleteUnusedRows ( Groups )
	
	count = Groups.Count();
	for i = 1 to count do
		row = Groups [ count - i ];
		if ( row.use = 0 ) then
			Groups.Delete ( row );
		else
			deleteUnusedRows ( row.rows );
		endif;
	enddo; 
	
EndProcedure

&AtServer
Procedure fillRightsByGroups ( Env, Groups );
	
	usedGroups = getUsedGroups ( Groups );
	groupRoles = getRolesByGroups ( usedGroups );
	list = Env.SelectedRights;
	for each role in groupRoles do
		if ( not RightsTree.InRole( Env, role ) ) then
			list.Add ( role );
		endif;
	enddo;
	
EndProcedure

&AtServer
Function getUsedGroups ( Groups )
	
	usedGroupsArray = new array;
	usedGroups = Groups.FindRows ( new Structure ( "Use", true ) );
	for each usedGroup in usedGroups do
		usedGroupsArray.Add ( usedGroup.Membership );
	enddo;
	return usedGroupsArray;
	
EndFunction

&AtServer
Function getRolesByGroups ( Groups )
	
	q = new Query ( "select RoleName as RoleName from Catalog.Membership.Rights where Ref in ( &Groups )" );
	q.SetParameter ( "Groups", Groups );
	return q.Execute ().Unload ().UnloadColumn ( "RoleName" );
	
EndFunction

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( limitReached () ) then
		Cancel = true;
		return;
	endif; 
	adjustClasses ();
	fillTimeZones ();
	if ( Object.Ref.IsEmpty () ) then
		readAccess ();
		Copy = not Parameters.CopyingValue.IsEmpty ();
		baseType = TypeOf ( Parameters.Basis );
		if ( baseType = Type ( "CatalogRef.Employees" ) ) then
			fillByEmployee ();
		elsif ( baseType = Type ( "CatalogRef.Organizations" ) ) then
			fillFieldsByOrganization ();
		else
			fillNew ();
		endif;
		setSettings ();
		setLogin ();
		setCurrentTimeZone ();
		fillMemberships ( ? ( Copy, Parameters.CopyingValue, Object.Ref ) );
		RightsTree.FillRights ( ThisObject );
		fillActualRights ();
	endif;
	initTenatsList ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|LimitedAccess show LimitedAccess;
	|TenantAccess show Sysadmin;
	|Tenants hide LimitedAccess or Login.TenantAccess = Enum.Access.Undefined;
	|UserClass Description FirstName LastName Patronymic Gender Email TimeZone
	|SetNewPassword Password PasswordConfirmation MustChangePassword lock LimitedAccess;
	|Password PasswordConfirmation enable SetNewPassword;
	|Organizations show Object.OrganizationAccess <> Enum.Access.States
	|	and inlist ( Object.OrganizationAccess, Enum.Access.Allow, Enum.Access.Forbid );
	|OrganizationsStates show Object.OrganizationAccess = Enum.Access.States;
	|Companies show Object.CompanyAccess <> Enum.Access.Undefined;
	|Employee show Object.UserClass = Enum.Users.StandardUser;
	|Employee hint/Output.AutoEmployee Object.UserClass = Enum.Users.StandardUser and empty ( Object.Ref );
	|CreateEmployee show not filled ( Object.Employee ) and Object.UserClass = Enum.Users.StandardUser
	|	and filled ( Object.Ref );
	|Warehouses show Object.WarehouseAccess <> Enum.Access.States
	|	and inlist ( Object.WarehouseAccess, Enum.Access.Allow, Enum.Access.Forbid );
	|WarehousesStates show Object.WarehouseAccess = Enum.Access.States;
	|Write show empty ( Object.Ref );
	|RightsEditRights enable Administrator;
	|TrackingPeriodicity show Object.TrackLocation = Enum.Tracking.Periodically;
	|TrackingTime TrackingDistance show Object.TrackLocation = Enum.Tracking.Always;
	|TrackingProvider show Object.TrackLocation <> Enum.Tracking.Never;
	|OSUser show Object.OSAuth;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Function limitReached ()
	
	if ( not Cloud.Cloud () ) then
		return false;
	endif;
	info = CloudPayments.GetInfo ();
	limit = not info.System
	and info.Today > info.EndOfTrialPeriod
	and info.EndOfTrialPeriod <> Date ( 1, 1, 1 )
	and ( info.UsersCount + 1 ) > info.PaidUsersCount;
	if ( limit ) then
		Output.LimitReached ();
	endif; 
	return limit;
	
EndFunction 

&AtServer
Procedure adjustClasses ()
	
	if ( Logins.Sysadmin () ) then
		Items.UserClass.ChoiceList.Add ( Enums.Users.HelpAgent );
	endif;
	
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
Procedure fillTimeZones ()
	
	timeZones = GetAvailableTimeZones ();
	for each timeZone in timeZones do
		Items.TimeZone.ChoiceList.Add ( timeZone, timeZone + " (" + TimeZonePresentation ( timeZone ) + ")" );
	enddo; 
	
EndProcedure 

&AtServer
Procedure fillNew ()
	
	if ( Copy ) then
		Object.Employee = undefined;
	endif;

EndProcedure

&AtServer
Procedure setSettings ()

	if ( Copy ) then
		readSettings ( Parameters.CopyingValue );
	else
		Catalogs.UserSettings.Init ( UserSettings );
	endif; 

EndProcedure 

&AtServer
Procedure setLogin ()

	Login.MustChangePassword = true;
	if ( Copy ) then
		friend = DF.Pick ( Parameters.CopyingValue, "Login" );
		readLogin ( friend );
		if ( Sysadmin
			or not accessIsLimited ( friend ) ) then
			return;
		endif;
	endif;
	tenants = Login.Tenants;
	tenants.Clear ();
	Login.TenantAccess = Enums.Access.Allow;
	row = tenants.Add ();
	row.Tenant = SessionParameters.Tenant;

EndProcedure 

&AtServer
Procedure setCurrentTimeZone ()
	
	currentTimeZone = GetInfoBaseTimeZone ();
	Object.TimeZone = ? ( currentTimeZone = undefined, TimeZone (), currentTimeZone );
	
EndProcedure 

&AtServer
Procedure fillByEmployee ()
	
	Object.Employee = Parameters.Basis;
	data = DF.Values ( Object.Employee, "FirstName, LastName, Patronymic, Email" );
	Object.Description = data.Email;
	Object.FirstName = data.FirstName;
	Object.LastName = data.LastName;
	Object.Patronymic = data.Patronymic;
	Object.Email = data.Email;
	setName ( Object );
	setCode ( Object );

EndProcedure 

&AtClientAtServerNoContext
Procedure setName ( Object )
	
	Object.FullName = ContactsForm.FullName ( Object );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setCode ( Object )
	
	Object.Code = Conversion.DescriptionToCode ( Object.Description );
	
EndProcedure 

&AtServer
Procedure fillFieldsByOrganization ()
	
	Object.UserClass = Enums.Users.Customer;
	Object.OrganizationAccess = Enums.Access.Allow;
	row = Object.Organizations.Add ();
	row.Organization = Parameters.Basis;
	
EndProcedure 

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageUserGroupCreated () ) then
		fillAccess ();
		expandTree ();
	elsif (	EventName = Enum.MessageUserGroupModified () ) then
		fillActualRights ();
		expandTree ();
	elsif ( EventName = Enum.MessageUserRightsChanged () ) then
		updateRights ( Parameter );
		expandTree ();
	endif; 
	
EndProcedure

&AtServer
Procedure fillAccess ()
	
	fillMemberships ( Object.Ref );
	fillActualRights ();
	
EndProcedure

&AtServer
Procedure updateRights ( val Address ) export
	
	table = GetFromTempStorage ( Address );
	ValueToFormData ( table, Rights );
	RightsTree.FillChanges ( ThisObject );
	fillActualRights ();
	
EndProcedure

&AtClient
Procedure expandTree ()
	
	RightsTree.Expand ( ThisObject, "ActualAccess" );

EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkRights () ) then
		Cancel = true;
	endif;
	if ( not checkLogin () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtServer
Function checkRights ()
	
	groupsSelected = Tables.Membership.FindRows ( new Structure ( "Use", true ) ).Count () > 0;
	if ( groupsSelected ) then
		return true;	
	else
		error = not RightsTree.FillCheck ( ThisObject );
		if ( error ) then
			if ( Tables.Membership.Count () = 0 ) then
				Output.SelectAccessRights ( , "Rights", , "" );
			else
				Output.SelectUsersGroup ( , "Tables.Membership", , "" );
			endif; 
		endif; 
		return not error;
	endif;
	
EndFunction 

&AtServer
Function checkLogin ()
	
	error = false;
	access = Login.TenantAccess;
	if ( access.IsEmpty () ) then
		Output.FieldIsEmpty ( , "TenantAccess", , "Login" );
		error = true;
	elsif ( access <> PredefinedValue ( "Enum.Access.Undefined" ) ) then
		table = Login.Tenants;
		if ( table.Count () = 0 ) then
			msg = new Structure ( "Table", Metadata.Catalogs.Logins.TabularSections.Tenants.Presentation () );
			Output.TableIsEmpty ( msg, "Tenants", , "Login" );
			error = true;
		else
			for each row in table do
				if ( row.Tenant.IsEmpty () ) then
					Output.FieldIsEmpty ( , Output.Row ( "Tenants", row.LineNumber, "Tenant" ), , "Login" );
					error = true;
				endif;
			enddo;
		endif;
		tenantFound = table.FindRows ( new Structure ( "Tenant", SessionParameters.Tenant ) ).Count () > 0;
		wrongAccess = ( access = PredefinedValue ( "Enum.Access.Allow" ) and not tenantFound )
			or ( access = PredefinedValue ( "Enum.Access.Forbid" ) and tenantFound );
		if ( wrongAccess ) then
			error = true;
			Output.WrongTenantAccess ();
		endif;
		doubles = Collections.GetDoubles ( table, "Tenant" );
		if ( doubles.Count () > 0 ) then
			error = true;
			for each row in doubles do
				Output.ValueDuplicated ( , Output.Row ( "Tenants", row.LineNumber, "Tenant" ), , "Login" );
			enddo; 
		endif;
	endif;
	ref = Object.Ref;
	if ( not ref.IsEmpty () ) then
		if ( DF.GetOriginal ( ref, "Description", Object.Description ) <> undefined ) then
			error = true;
			Output.LoginAlreadyExists ( , "Description" );
		endif;
	endif;
	return not error;

EndFunction

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not CurrentObject.IsNew () ) then
		OldTenants = Catalogs.Users.GetTenants ( Object.Ref );
	endif;
	resetAccessRevoking ( CurrentObject );
	saveLogin ( CurrentObject );
	setProperties ( CurrentObject );
	setEmployee ( CurrentObject );
	RightsTree.SaveSeletedRights ( ThisObject, CurrentObject );
	
EndProcedure

&AtServer
Procedure resetAccessRevoking ( CurrentObject )
	
	if ( not CurrentObject.AccessRevoked ) then
		return;
	endif;
	access = Login.TenantAccess;
	inList = Login.Tenants.FindRows ( new Structure ( "Tenant", SessionParameters.Tenant ) ).Count () > 0;
	CurrentObject.AccessRevoked = ( access = Enums.Access.Forbid and inList )
	or ( access = Enums.Access.Allow and not inList );
	
EndProcedure

&AtServer
Procedure saveLogin ( CurrentObject )
	
	obj = FormAttributeToValue ( "Login" );
	if ( obj.Modified () ) then
		obj.Description = Object.Description;
		obj.Write ();
		CurrentObject.Login = obj.Ref;
		ValueToFormAttribute ( obj, "Login" );
	endif;
	
EndProcedure

&AtServer
Procedure setProperties ( CurrentObject )
	
	p = CurrentObject.AdditionalProperties;
	if ( SetNewPassword ) then
		p.Insert ( Enum.AdditionalPropertiesPassword (), Password );
	endif;
	p.Insert ( Enum.AdditionalPropertiesMembership (), selectedGroups () );
	
EndProcedure

&AtServer
Function selectedGroups ()
	
	list = new Array ();
	for each row in Tables.Membership.Unload () do
		if ( row.Use ) then
			list.Add ( row.Membership );
		endif;
	enddo;
	return list;
	
EndFunction 

&AtServer
Procedure setEmployee ( CurrentObject )

	if ( Object.UserClass <> Enums.Users.StandardUser ) then
		return;
	endif;
	if ( CurrentObject.Employee.IsEmpty () ) then
		if ( CurrentObject.IsNew () ) then
			CurrentObject.Employee = newEmployee ();
		endif;
	else
		updateEmployee ();
	endif;
	
EndProcedure

&AtServer
Function newEmployee ()
	
	data = findEmployee ();
	if ( data.Employee = undefined ) then
		return makeEmployee ( data.Individual );
	else
		return data.Employee;
	endif;

EndFunction

&AtServer
Function findEmployee ()
	
	s = "
	|select top 1 Individuals.Ref as Individual, Employees.Ref as Employee
	|from Catalog.Individuals as Individuals
	|	//
	|	// Employees
	|	//
	|	left join Catalog.Employees as Employees
	|	on Employees.Individual = Individuals.Ref
	|	and not Employees.DeletionMark
	|where not Individuals.DeletionMark
	|and Individuals.FirstName = &FirstName
	|and Individuals.LastName = &LastName
	|and Individuals.Patronymic = &Patronymic
	|and Individuals.Gender = &Gender";
	q = new Query ( s );
	q.SetParameter ( "FirstName", Object.FirstName );
	q.SetParameter ( "LastName", Object.LastName );
	q.SetParameter ( "Patronymic", Object.Patronymic );
	q.SetParameter ( "Gender", Object.Gender );
	table = q.Execute ().Unload ();
	return Conversion.RowToStructure ( table );
	
EndFunction

&AtServer
Function makeEmployee ( Person )
	
	if ( Person = undefined ) then
		individual = createIndividual ();
	else
		individual = Person.GetObject ();
	endif;
	employee = Catalogs.Employees.CreateItem ();
	employee.Individual = individual.Ref;
	employee.EmployeeType = Enums.EmployeeTypes.Employee;
	employee.Company = UserSettings.Company;
	employee.DataExchange.Load = true;
	Catalogs.Employees.Update ( employee, individual );
	DF.SetNewCode ( employee );
	employee.Write ();
	return employee.Ref;
	
EndFunction

&AtServer
Function createIndividual ()
	
	obj = Catalogs.Individuals.CreateItem ();
	FillPropertyValues ( obj, Object, "FirstName, LastName, Patronymic, Gender, Email" );
	obj.Description = object.FullName;
	DF.SetNewCode ( obj );
	obj.Write ();
	return obj;
	
EndFunction

&AtServer
Procedure updateEmployee ()
	
	if ( nameChanged () ) then
		employee = Object.Employee.GetObject ();
		individual = employee.Individual.GetObject ();
		FillPropertyValues ( individual, Object, "FirstName, LastName, Patronymic, Gender, Email" );
		individual.Description = object.FullName;
		individual.Write ();
		employee.DataExchange.Load = true;
		Catalogs.Employees.Update ( employee, individual );
		employee.Write ();
	endif;
	
EndProcedure

&AtServer
Function nameChanged ()
	
	s = "
	|select top 1 1
	|from Catalog.Employees as Employees
	|where Employees.Ref = &Employee
	|and Employees.FirstName = &FirstName
	|and Employees.LastName = &LastName
	|and Employees.Patronymic = &Patronymic
	|and Employees.Gender = &Gender";
	q = new Query ( s );
	q.SetParameter ( "Employee", Object.Employee );
	q.SetParameter ( "FirstName", Object.FirstName );
	q.SetParameter ( "LastName", Object.LastName );
	q.SetParameter ( "Patronymic", Object.Patronymic );
	q.SetParameter ( "Gender", Object.Gender );
	return q.Execute ().IsEmpty ();

EndFunction

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not writeSettings ( CurrentObject ) ) then
		Cancel = true;
		return;
	endif;
	syncUsers ( CurrentObject );
	
EndProcedure

&AtServer
Function writeSettings ( CurrentObject )

	settings = FormAttributeToValue ( "UserSettings" );
	settings.AdditionalProperties.Insert ( Enum.AdditionalPropertiesWritingUser (), ThisObject );
	if ( settings.Owner.IsEmpty () ) then
		settings.Owner = CurrentObject.Ref;
	endif;
	if ( not settings.CheckFilling () ) then
		return false;
	endif;
	if ( settings.Modified () ) then
		settings.Write ();
		ValueToFormAttribute ( settings, "UserSettings" );
	endif;
	return true;

EndFunction

&AtServer
Procedure syncUsers ( CurrentObject )
	
	p = DataProcessors.SyncUsers.GetParams ();
	p.OldTenants = OldTenants;
	p.User = CurrentObject.Ref;
	args = new Array ();
	args.Add ( "SyncUsers" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID );
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Syncing = true;
	Progress.Open ( UUID, , new NotifyDescription ( "SyncingCompleted", ThisObject ), true );
	if ( MyProfile ) then
		UpdateAppCaption ();
		AttachEmailCheck ();
	endif; 
	Notify ( Enum.MessageUserIsSaved (), Object.Employee );
	
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
// *********** Page User

&AtClient
Procedure DescriptionOnChange ( Item )
	
	adjustLogin ();
	setFirstName ();
	setCode ( Object );
	
EndProcedure

&AtClient
Procedure adjustLogin ()
	
	Object.Description = TrimAll ( Object.Description );
	
EndProcedure 

&AtClient
Procedure setFirstName ()
	
	Object.FirstName = Object.Description;
	setName ( Object );
	
EndProcedure 

&AtClient
Procedure OSAuthOnChange ( Item )
	
	applyAuth ();
	
EndProcedure

&AtClient
Procedure applyAuth ()
	
	if ( Object.OSAuth ) then
		if ( Object.OSUser = "" ) then
			Object.OSUser = Object.Description;
		endif;
	else
		Object.OSUser = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.OSAuth" );
	
EndProcedure

&AtClient
Procedure NameOnChange ( Item )
	
	setName ( Object );
	
EndProcedure

&AtClient
Procedure SetNewPasswordOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "SetNewPassword" );
	
EndProcedure

&AtClient
Procedure EmployeeOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Employee" );
	
EndProcedure

&AtClient
Procedure UserClassOnChange ( Item )
	
	resetEmployee ();
	Appearance.Apply ( ThisObject, "Object.UserClass" );
	
EndProcedure

&AtClient
Procedure resetEmployee ()
	
	if ( Object.UserClass = PredefinedValue ( "Enum.Users.StandardUser" ) ) then
		return;
	endif; 
	Object.Employee = undefined;
	
EndProcedure 

&AtClient
Procedure CreateEmployee ( Command )
	
	createNewEmployee ();
	
EndProcedure

&AtClient
Procedure createNewEmployee ()
	
	p = new Structure ( "User, ChoiceMode", Object.Ref, true );
	OpenForm ( "Catalog.Employees.ObjectForm", p, Items.Employee );
	
EndProcedure

&AtClient
Procedure DocumentsFolderStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	LocalFiles.Prepare ( new NotifyDescription ( "ChooseFolder", ThisObject ) );
	
EndProcedure

&AtClient
Procedure ChooseFolder ( Result, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.ChooseDirectory );
	dialog.Show ( new NotifyDescription ( "SelectFolder", ThisObject ) );
	
EndProcedure 

&AtClient
Procedure SelectFolder ( Folder, Params ) export
	
	if ( Folder = undefined ) then
		return;
	endif; 
	Object.Folder = Folder [ 0 ];
	
EndProcedure 

// *****************************************
// *********** Page Access

&AtClient
Procedure MarkAllGroups ( Command )
	
	Forms.MarkRows ( Tables.Membership, true );
	fillActualRights ();
	expandTree ();
	
EndProcedure

&AtClient
Procedure UnmarkAllGroups ( Command )
	
	Forms.MarkRows ( Tables.Membership, false );
	fillActualRights ();
	expandTree ();
	
EndProcedure

&AtClient
Procedure MembershipBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure MembershipBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure MembershipSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	openSeletedUserGroup ( Item );
	
EndProcedure

&AtClient
Procedure openSeletedUserGroup ( Item )
	
	ShowValue ( , Item.CurrentData.Membership );
	
EndProcedure 

&AtClient
Procedure EditRights ( Command )
	
	openEditor ();
	
EndProcedure

&AtClient
Procedure openEditor ()
	
	p = new Structure ();
	p.Insert ( "UserRights", storeRights () );
	OpenForm( "Catalog.Users.Form.Rights", p, ThisObject );
	
EndProcedure 

&AtServer
Function storeRights ()
	
	return PutToTempStorage ( FormDataToValue ( Rights, Type ( "ValueTree" ) ) );

EndFunction
	
&AtClient
Procedure MembershipUseOnChange ( Item )
	
	fillActualRights ();
	expandTree ();
	
EndProcedure

&AtClient
Procedure CompanyAccessOnChange ( Item )
	
	clearCompanies ();
	Appearance.Apply ( ThisObject, "Object.CompanyAccess" );
	
EndProcedure

&AtClient
Procedure clearCompanies ()
	
	if ( Object.CompanyAccess = PredefinedValue ( "Enum.Access.Undefined" ) ) then
		Object.Companies.Clear ();
	endif; 
	
EndProcedure 

&AtClient
Procedure OrganizationAccessOnChange ( Item )
	
	adjustAccess ( "Organizations" );
	Appearance.Apply ( ThisObject, "Object.OrganizationAccess" );
	
EndProcedure

&AtClient
Procedure adjustAccess ( Class )
	
	if ( Class = "Organizations" ) then
		access = Object.OrganizationAccess;
		table = Object.Organizations;
		states = Object.OrganizationsStates;
	elsif ( Class = "Warehouses" ) then
		access = Object.WarehouseAccess;
		table = Object.Warehouses;
		states = Object.WarehousesStates;
	endif; 
	if ( access = PredefinedValue ( "Enum.Access.Undefined" )
		or access = PredefinedValue ( "Enum.Access.Directly" )
		or access = PredefinedValue ( "Enum.Access.States" ) ) then
		table.Clear ();
	endif;
	if ( access <> PredefinedValue ( "Enum.Access.States" ) ) then
		states.Clear ();
	endif; 
	
EndProcedure 

&AtClient
Procedure WarehouseAccessOnChange ( Item )
	
	adjustAccess ( "Warehouses" );
	Appearance.Apply ( ThisObject, "Object.WarehouseAccess" );
	
EndProcedure

&AtClient
Procedure TenantAccessOnChange ( Item )

	clearTenants ();
	Appearance.Apply ( ThisObject, "Login.TenantAccess" );

EndProcedure

&AtClient
Procedure clearTenants ()
	
	if ( Login.TenantAccess = PredefinedValue ( "Enum.Access.Undefined" ) ) then
		Login.Tenants.Clear ();
	endif; 
	
EndProcedure 

// *****************************************
// *********** Page Location

&AtClient
Procedure TrackLocationOnChange ( Item )
	
	applyTrackLocation ();
	
EndProcedure

&AtClient
Procedure applyTrackLocation ()
	
	if ( Object.TrackLocation = PredefinedValue ( "Enum.Tracking.Always" ) ) then
		Object.TrackingDistance = 300;
		Object.TrackingTime = PredefinedValue ( "Enum.Frequency.Every30m" );
	elsif ( Object.TrackLocation = PredefinedValue ( "Enum.Tracking.Periodically" ) ) then
		Object.TrackingPeriodicity = PredefinedValue ( "Enum.Frequency.Every30m" );
	else
		Object.TrackingDistance = 0;
		Object.TrackingTime = undefined;
		Object.TrackingPeriodicity = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.TrackLocation" );
	
EndProcedure

// *****************************************
// *********** Page More

&AtClient
Procedure LoginOnChange ( Item )
	
	applyLogin ();
	
EndProcedure

&AtServer
Procedure applyLogin ()

	readLogin ( Object.Login );
	Object.Description = Login.Description;
	Appearance.Apply ( ThisObject, "Login.TenantAccess" );

EndProcedure
