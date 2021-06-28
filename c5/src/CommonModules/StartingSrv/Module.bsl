
Function TenantDeactivated () export
	
	deactivated = DF.Pick ( SessionParameters.Tenant, "Deactivated" );
	return deactivated;
	
EndFunction 

Function SetFirstLogin () export
	
	first = CommonSettingsStorage.Load ( Enum.SettingsFirstLogin () );
	if ( first = undefined or first ) then
		LoginsSrv.SaveSettings ( Enum.SettingsFirstLogin (), , false );
		return true;
	else
		return false;
	endif; 
	
EndFunction 

Function Info () export
	
	return Cloud.Info ();
	
EndFunction 

Procedure InitNode () export
	
	SetPrivilegedMode ( true );
	ExchangePlans.Full.ReadData ();
	ExchangePlans.Full.ReadChanges ();
	SetPrivilegedMode ( false );
	
EndProcedure

Function CurrentCompany () export
	
	company = Logins.Settings ( "Company" ).Company;
	return String ( company );
	
EndFunction 

Function NewSession ( val Computer, val WebClient, val MobileClient, val ThinClient, val ThickClient, val Linux ) export
	
	SetPrivilegedMode ( true );
	host = getComputer ( Computer );
	session = findSession ( host, WebClient, MobileClient, ThinClient, ThickClient, Linux );
	if ( session = undefined ) then
		session = createSession ( host, WebClient, MobileClient, ThinClient, ThickClient, Linux );
	endif; 
	SessionParameters.Session = session;
	SetPrivilegedMode ( false );
	return session;
	
EndFunction

Function getComputer ( Name )
	
	host = Catalogs.Computers.FindByDescription ( Name, true );
	if ( host.IsEmpty () ) then
		obj = Catalogs.Computers.CreateItem ();
		obj.Description = Name;
		obj.Write ();
		host = obj.Ref;
	endif; 
	return host;
	
EndFunction 

Function findSession ( Host, WebClient, MobileClient, ThinClient, ThickClient, Linux )
	
	s = "
	|select top 1 Sessions.Ref as Ref
	|from Catalog.Sessions as Sessions
	|where not Sessions.DeletionMark
	|and Sessions.Computer = &Computer
	|and Sessions.User = &User
	|and Sessions.WebClient = &WebClient
	|and Sessions.MobileClient = &MobileClient
	|and Sessions.ThinClient = &ThinClient
	|and Sessions.ThickClient = &ThickClient
	|and Sessions.Linux = &Linux
	|";
	q = new Query ( s );
	q.SetParameter ( "Computer", Host );
	q.SetParameter ( "User", SessionParameters.User );
	q.SetParameter ( "WebClient", WebClient );
	q.SetParameter ( "MobileClient", MobileClient );
	q.SetParameter ( "ThinClient", ThinClient );
	q.SetParameter ( "ThickClient", ThickClient );
	q.SetParameter ( "Linux", Linux );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Function createSession ( Host, WebClient, MobileClient, ThinClient, ThickClient, Linux )
	
	obj = Catalogs.Sessions.CreateItem ();
	obj.Computer = Host;
	obj.User = SessionParameters.User;
	obj.Description = Host;
	obj.WebClient = WebClient;
	obj.MobileClient = MobileClient;
	obj.ThinClient = ThinClient;
	obj.ThickClient = ThickClient;
	obj.Linux = Linux;
	obj.Write ();
	return obj.Ref;
	
EndFunction 

Function CheckLicense () export
	
	return DataProcessors [ Enum.DataProcessorsLicensing () ].Check ();
	
EndFunction

Function SessionInfo () export
	
	SetPrivilegedMode ( true );
	p = new Structure ( "Rooted, Testing, Master, Cloud, Admin, Sysadmin, CheckUpdates, NewUpdates, UpdateRequired,
	|FirstStart, AccessDenied, AccessRevoked, Unlimited, MustChangePassword" );
	p.Testing = TesterCache.Testing ();
	master = ExchangePlans.MasterNode () = undefined;
	p.Master = master;
	p.Cloud = Cloud.Cloud ();
	p.Admin = Logins.Admin ();
	p.UpdateRequired = master
	and DataProcessors.UpdateInfobase.Required ();
	sysadmin = Logins.Sysadmin ();
	p.Sysadmin = sysadmin;
	p.NewUpdates = sysadmin and Constants.NewUpdates.Get ();
	p.Unlimited = IsInRole ( "AdministratorSystem" )
	or IsInRole ( "Unlimited" );
	rooted = Logins.Rooted ();
	p.Rooted = rooted;
	if ( not rooted ) then
		p.FirstStart = Logins.Admin () and Constants.FirstStart.Get ();
		p.CheckUpdates = sysadmin and Constants.CheckUpdates.Get ();
		data = DF.Values ( SessionParameters.User, "AccessDenied, AccessRevoked, Login.MustChangePassword as MustChangePassword" );
		p.AccessDenied = data.AccessDenied;
		p.AccessRevoked = data.AccessRevoked;
		p.MustChangePassword = data.MustChangePassword;
	endif;
	return p;
	
EndFunction

Function RunUpdate ( Error ) export
	
	if ( not DataProcessors.UpdateInfobase.TryStart () ) then
		Error = Output.UpdateAlreadyStarted ();
		return undefined;
	endif;
	args = new Array ();
	args.Add ( "UpdateInfobase" );
	id = "InfobaseUpdate";
	Jobs.Run ( "Jobs.ExecProcessor", args, id, , TesterCache.Testing () );
	return id;
	
EndFunction

Procedure CheckUpdates ( FirstTime ) export
	
	params = new Array ();
	params.Add ( FirstTime );
	Jobs.Run ( "ApplicationUpdates.Check", params, , , TesterCache.Testing () );
	
EndProcedure

Function GetCopies () export
	
	return Connections.GetCopies ();
	
EndFunction

Procedure DisconnectCopies () export
	
	Connections.DisconnectCopies ();
	
EndProcedure

Procedure AcceptUpdate () export
	
	// We check the access because system can be activated (through Tenant Activation)
	// after update under user with basic access rights
	if ( AccessRight ( "Update", Metadata.Constants.NewUpdates ) ) then
		Constants.NewUpdates.Set ( false );
	endif;
	
EndProcedure

Procedure UnlockDB () export
	
	Connections.Unlock ();
	
EndProcedure

Function GetUser () export

	return SessionParameters.User;

EndFunction
