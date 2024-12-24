#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Outside;
var Error;

Function Enroll () export

	result = new Structure ( "Tenant, Error" );
	if ( findTenant () <> undefined ) then
		result.Error = "TenantAlreadyExists";
		return result;
	endif; 
	BeginTransaction ();
	if ( IsBlankString ( Parameters.PromoCode ) ) then
		promoCode = undefined;
	else
		promoCode = getPromoCode ();
		if ( promoCode = undefined ) then
			result.Error = "PromoCodeError";
			return result;
		endif; 
		if ( not checkPromoCode ( promoCode ) ) then
			result.Error = "PromoCodeError";
			return result;
		endif; 
	endif;
	tenant = newTenant ( promoCode );
	activateTenant ( tenant.Ref );
	createMasterNode ();
	createSlaveNode ( tenant );
	createExchangeUser ( tenant );
	if ( not loadInitialData () ) then
		raise Error;
	endif;
	InitializePredefinedData ();
	setAdministrativeUser ();
	setCompany ( Parameters );
	setFirstStart ();
	CommitTransaction ();
	result.Tenant = tenant.Code;
	return result;

EndFunction

Function findTenant ()
	
	s = "
	|select top 1 Tenants.Ref as Ref
	|from Catalog.Tenants as Tenants
	|where Tenants.Description = &Email
	|";
	q = new Query ( s );
	q.SetParameter ( "Email", Parameters.Email );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function getPromoCode ()
	
	s = "
	|select PromoCodes.Ref as Ref
	|from Catalog.PromoCodes as PromoCodes
	|where not PromoCodes.DeletionMark
	|and not PromoCodes.IsFolder
	|and PromoCodes.Code = &PromoCode
	|";
	q = new Query ( s );
	q.SetParameter ( "PromoCode", Parameters.PromoCode  );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );

EndFunction 

Function checkPromoCode ( PromoCode )
	
	blockPromoCode ( PromoCode );
	fields = DF.Values ( PromoCode, "ExpirationDate, Finish" );
	if ( fields.ExpirationDate < CurrentSessionDate () ) then
		return false;
	endif; 
	alreadyActivated = fields.Finish <> Date ( 1, 1, 1 );
	if ( alreadyActivated ) then
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure blockPromoCode ( PromoCode )
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.PromoCodes" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Ref", PromoCode );
	lock.Lock ();
	
EndProcedure 

Function newTenant ( PromoCode )
	
	lockTenants ();
	tenantCode = getNewTenantCode ();
	obj = Catalogs.Tenants.CreateItem ();
	obj.Code = tenantCode;
	if ( PromoCode <> undefined ) then
		obj.PromoCode = PromoCode;
		obj.AgentTenant = DF.Pick ( PromoCode, "Agent.Tenant" );
	endif; 
	obj.Description = Parameters.Email;
	obj.RegistrationDate = CurrentSessionDate ();
	obj.EndOfTrialPeriod = obj.RegistrationDate + Constants.TrialPeriod.Get () * 86400;
	obj.Write ();
	return obj;
	
EndFunction 

Procedure lockTenants ()

	lock = new DataLock ();
	item = lock.Add ( "Catalog.Tenants" );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure

Function getNewTenantCode ()
	
	for i = 0 to 15 do
		code = generateCode ();
		tenant = Catalogs.Tenants.FindByCode ( code );
		if ( tenant.IsEmpty () ) then
			return code;
		endif; 
	enddo; 
	raise Output.CantCreateTenantCode ();
	
EndFunction 

Function generateCode ()
	
	return Upper ( StrReplace ( Left ( "" + new UUID (), 11 ), "-", "" ) );
	
EndFunction 

Procedure activateTenant ( Tenant )
	
	SessionParameters.Tenant = Tenant;
	SessionParameters.TenantUse = true;

EndProcedure 

Procedure createMasterNode ()
	
	code = getCode ( 1, Metadata.ExchangePlans.MobileServers );
	name = "This Node";
	node = ExchangePlans.MobileServers.ThisNode ().GetObject ();
	node.Code = code;
	node.Description = name;
	node.Write ();
	obj = Catalogs.Exchange.CreateItem ();
	obj.Description = name;
	obj.Code = code;
	obj.Node = node.Ref;
	obj.Write ();
	
EndProcedure 

Function getCode ( Code, Plan )
	
	return Format ( Code, "ND=" + Plan.CodeLength + "; NLZ=; NG=" );
	
EndFunction 

Procedure createSlaveNode ( Tenant )
	
	code = getCode ( 2, Metadata.ExchangePlans.MobileServers );
	name = "Mobile Server";
	node = ExchangePlans.MobileServers.CreateNode ();
	node.Code = code;
	node.Classifiers = getCode ( 2, Metadata.ExchangePlans.Classifiers );
 	node.Description = name;
	node.Write ();
	obj = Catalogs.Exchange.CreateItem ();
	obj.Description = name;
	obj.Code = code;
	obj.Node = node.Ref;
	obj.PrefixFileName = Tenant.Code;
	obj.OperationType = Enums.ExchangeTypes.NetworkDisk;
	obj.Periodicity = Enums.ExchangePeriodicity.Daily;
	obj.UseAutomatic = true;
	file = Constants.MobileRules.Get ();
	folder = FileSystem.GetFolder ( file );
	obj.UserTenant = Cloud.ExchangeUser ();
	obj.FolderDiskLoadHandle = folder;
	obj.FolderDiskLoadScheduledJob = folder;
	obj.FolderDiskUnLoadHandle = folder;
	obj.FolderDiskUnLoadJob = folder;
	obj.UseRules = Enums.ExchangeRules.File;
	obj.FileRules = file;
	obj.UseRulesClassifiers = Enums.ExchangeRules.File;
	obj.FileRulesClassifiers = Constants.ClassifiersRules.Get ();
	obj.Write ();
	
EndProcedure 

Procedure createExchangeUser ( Tenant )
	
	separated = LoginsSrv.Separated ();
	name = Cloud.ExchangeUser ();
	if ( separated
		or InfoBaseUsers.FindByName ( name ) = undefined ) then
		name = Cloud.ExchangeUser ();
		if ( name = "" ) then
			name = "_exchange";
		endif;
		user = InfoBaseUsers.CreateUser ();
		user.Name = name;
		User.Password = Constants.ExchangePassword.Get ();
		user.FullName = name;
		if ( separated ) then
			user.DataSeparation.Insert ( "Tenant", Tenant.Code );
		endif;
		languages = Metadata.Languages;
		english = languages.Find ( "English" );
		user.Language = ? ( english = undefined, languages.Russian, english );
		user.ShowInList = false;
		user.Roles.Add ( Metadata.Roles.Exchange );
		user.Write ();
	endif;
	
EndProcedure

Function loadInitialData ()
	
	loadXML = DataProcessors.Exchange.Create ();
	file = Constants.Initdb.Get ();
	if ( file = "" ) then
		cleanFile = true;
		file = GetTempFileName ();
		DataProcessors.CreateTenant.GetTemplate ( "Init" ).Write ( file );
	else
		cleanFile = false;
	endif;
	loadXML.ИмяФайлаОбмена = file; 
	loadXML.РежимОбмена = "Загрузка";
	loadXML.НеВыводитьНикакихИнформационныхСообщенийПользователю = true;
	ok = true;
	try
		loadXML.ВыполнитьЗагрузку ();
	except
		Error = BriefErrorDescription ( ErrorInfo () );
		ok = false;
	endtry;
	if ( cleanFile ) then
		DeleteFiles ( file );
	endif;
	return ok;
	
EndFunction 

Procedure setAdministrativeUser ()
	
	selection = Catalogs.Users.Select ();
	selection.Next ();
	user = selection.GetObject ();
	userName = Parameters.User;
	user.Description = userName;
	user.FirstName = userName;
	creator = Parameters.Creator;
	if ( creator = undefined ) then
		user.Email = Parameters.Email;
		user.Language = Parameters.Language;
		user.Protection = Parameters.Protection;
		user.OSAuth = Parameters.OSAuth;
		user.OSUser = Parameters.OSUser;
		user.Show = Parameters.Show;
		user.Login = newLogin ();
		setAdministrativeEmployee ( Parameters, user );
		user.AdditionalProperties.Insert ( "Password", Parameters.Password );
	else
		updateLogin ();
		user.Login = creator;
	endif;
	user.Code = Conversion.DescriptionToCode ( userName );
	user.Write ();
	Constants.MainUser.Set ( user.Ref );
	
EndProcedure

Function newLogin ()

	login = Catalogs.Logins.CreateItem ();
	login.Description = Parameters.User;
	login.TenantAccess = Enums.Access.Allow;
	row = login.Tenants.Add ();
	row.Tenant = SessionParameters.Tenant;
	login.Write ();
	return login.Ref;

EndFunction

Procedure setAdministrativeEmployee ( Params, User )
	
	employee = User.Employee.GetObject ();
	employee.Description = Params.User;
	employee.FirstName = Params.User;
	employee.Email = Params.Email;
	employee.Write ();
	
EndProcedure

Procedure updateLogin ()
	
	creator = Parameters.Creator;
	access = DF.Pick ( creator, "TenantAccess" );
	hasEverything = access <> Enums.Access.Allow; 
	if ( hasEverything ) then
		return;
	endif;
	obj = creator.GetObject ();
	row = obj.Tenants.Add ();
	row.Tenant = SessionParameters.Tenant;
	obj.Write ();
	
EndProcedure

Procedure setCompany ( Params )
	
	selection = Catalogs.Companies.Select ();
	selection.Next ();
	obj = selection.GetObject ();
	obj.Description = Params.Company;
	obj.FullDescription = Params.Company;
	obj.Write ();
	Constants.Company.Set ( obj.Ref );
	
EndProcedure 

Procedure setFirstStart ()
	
	Constants.FirstStart.Set ( true );
	
EndProcedure 

Procedure Exec () export

	BeginTransaction ();
	oldTenant = SessionParameters.Tenant;
	tenant = newOrganization ();
	if ( tenant = undefined ) then
		RollbackTransaction ();
		sendError ();
		return;
	endif;
	users = getUsers ();
	tenantRef = tenant.Ref;
	try
		activateTenant ( tenantRef );
	except
		Error = BriefErrorDescription ( ErrorInfo () );
		RollbackTransaction ();
		sendError ();
		return;
	endtry;
	createMasterNode ();
	createSlaveNode ( tenant );
	createExchangeUser ( tenant );
	if ( not loadInitialData () ) then
		RollbackTransaction ();
		return;
	endif;
	InitializePredefinedData ();
	setAdministrativeUser ();
	setCompany ( Parameters );
	setFirstStart ();
	activateTenant ( oldTenant );
	if ( not assignUsers ( users ) ) then
		RollbackTransaction ();
		return;
	endif;
	CommitTransaction ();
	PutToTempStorage ( tenantRef, Parameters.Result );

EndProcedure

Procedure sendError ()
	
	Progress.Put ( Error, JobKey, true );
	
EndProcedure

Function newOrganization ()
	
	try
		tenantCode = getNewTenantCode ();
	except
		Error = BriefErrorDescription ( ErrorInfo () );
		return undefined;
	endtry;
	lockTenants ();
	obj = Catalogs.Tenants.CreateItem ();
	obj.Code = tenantCode;
	obj.Description = Parameters.Company;
	obj.RegistrationDate = CurrentSessionDate ();
	obj.Write ();
	return obj;
	
EndFunction

Function getUsers ()

	s = "select Users.Ref as User
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and not Users.AccessDenied
	|and not Users.AccessRevoked
	|and Users.Login.TenantAccess in (
	|	value ( Enum.Access.Undefined ),
	|	value ( Enum.Access.Forbid )
	|)
	|union
	|select Ref from Catalog.Users where Login = &Creator";
	q = new Query ( s );
	q.SetParameter ( "Creator", Parameters.Creator );
	return q.Execute ().Unload ().UnloadColumn ( "User" );

EndFunction

Function assignUsers ( Users )
	
	p = DataProcessors.SyncUsers.GetParams ();
	for each user in Users do
		p.User = user;
		if ( not DataProcessors.SyncUsers.Perform ( p, JobKey ) ) then
			return false;
		endif;
	enddo;
	return true;
	
EndFunction

#endif
