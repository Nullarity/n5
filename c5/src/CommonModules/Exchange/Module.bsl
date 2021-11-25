
Procedure Router ( Stage = undefined, Tenant = undefined, Node = undefined ) export
	
	if ( Stage = undefined ) then
		start ();
	elsif ( Stage = 1 ) then
		stage1 ( Tenant );
	elsif ( Stage = 2 ) then
		stage2 ( Tenant, Node );
	endif;
	
EndProcedure

Procedure start ( Delay = false )
	
	SetPrivilegedMode ( true );
	if ( Delay ) then
		delayStart ();
	else
		Constants.ExchangeStart.Set ( CurrentSessionDate () );
		tenant = getTenant ();
		if ( tenant = undefined ) then
			delayStart ();
		else
			p = new Array;
			p.Add ( 1 );
			p.Add ( tenant );
			job = newJob ( Metadata.ScheduledJobs.StartExchange );
			job.Parameters = p;
			job.UserName = Cloud.User ();
			job.Schedule = wait ();
			job.Description = "Stage 1";
			job.Write ();
			logging ( job, tenant.Code, "-" );
		endif;
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure

Procedure delayStart ()
	
	job = newJob ( Metadata.ScheduledJobs.StartExchange );
	job.Parameters = undefined;
	job.UserName = "";
	job.Description = "Start";
	job.Schedule = wait ( 60 );
	job.Write ();
	logging ( job, "-", "-" );
	
EndProcedure 

Function getTenant ()
	
	s = "
	|select top 1 History.Tenant as Ref, History.Tenant.Code as Code
	|from InformationRegister.ExchangeHistory as History
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on Constants.ExchangeStart > History.Date
	|and not History.Tenant.Deactivated
	|and not History.Tenant.DeletionMark
	|order by History.Date
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return undefined;
	endif; 
	row = table [ 0 ];
	data = new Structure ( "Ref, Code", row.Ref, row.Code );
	return data;
	
EndFunction

Function newJob ( Type )
	
	job = ScheduledJobs.FindPredefined ( Type );
	job.Schedule = wait ();
	job.RestartCountOnFailure = Type.RestartCountOnFailure;
	job.RestartIntervalOnFailure = Type.RestartIntervalOnFailure;
	job.Use = true;
	return job;
	
EndFunction 

Function wait ( Seconds = 1 )
	
	now = CurrentSessionDate ();
	today = BegOfDay ( now );
	schedule = new JobSchedule ();
	schedule.BeginDate = today;
	schedule.BeginTime = now - today + Seconds;
	schedule.WeeksPeriod = 0;
	schedule.RepeatPeriodInDay = 0;
	schedule.DaysRepeatPeriod = 0;
	return schedule;
	
EndFunction 

Procedure logging ( Job, Tenant, Node )
	
	p = new Structure ( "Description, Tenant, User, Node" );
	p.Description = job.Description;
	p.User = job.UserName;
	p.Tenant = Tenant;
	p.Node = Node;
	Output.JobScheduled ( p, "ScheduledJob.StartExchange" );

EndProcedure 

Procedure stage1 ( Tenant )
	
	activateTenant ( Tenant.Ref );
	delayStage2 ( Tenant );
	
EndProcedure

Procedure activateTenant ( Tenant )
	
	SessionParameters.Tenant = Tenant.Ref;
	SessionParameters.TenantUse = true;
	
EndProcedure 

Procedure delayStage2 ( Tenant )
	
	node = getNode ();
	if ( node = undefined ) then
		finishStage2 ( Tenant );
	else
		p = new Array;
		p.Add ( 2 );
		p.Add ( Tenant );
		p.Add ( node.Ref );
		job = newJob ( Metadata.ScheduledJobs.Exchange );
		job.UserName = node.User;
		job.Description = "Stage 2";
		job.Parameters = p; 
		job.DataSeparation.Insert ( "Tenant", Tenant.Ref );
		job.Write ();
		logging ( job, Tenant.Code, node.Ref );
	endif;
	
EndProcedure 

Procedure finishStage2 ( Tenant )
	
	stampTenant ( Tenant.Ref );
	deactivateTenant ();
	start ( true );
		
EndProcedure 

Function getNode ()
	
	s = "
	|select top 1 Exchange.Ref as Ref, Exchange.Node as Node, Exchange.Node.ThisNode as ThisNode,
	|	case when Exchange.UserTenant refs Catalog.Users then Exchange.UserTenant.Description
	|		when Exchange.UserTenant = undefined then Constants.ExchangeUser
	|		else Exchange.UserTenant
	|	end as User
	|from Catalog.Exchange as Exchange
	|	//
	|	// Constants
	|	//
	|	join Constants as Constants
	|	on Constants.ExchangeStart > Exchange.LastExchange
	|where Exchange.UseAutomatic
	|and not Exchange.Node.ThisNode
	|order by Exchange.LastExchange
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction 

Procedure stampTenant ( Tenant )
	
	r = InformationRegisters.ExchangeHistory.CreateRecordManager ();
	r.Tenant = Tenant;
	r.Date = CurrentSessionDate ();
	r.Write ();	
	
EndProcedure 

Procedure deactivateTenant ()
	
	SessionParameters.TenantUse = false;
	SessionParameters.Tenant = Catalogs.Tenants.EmptyRef ();
	
EndProcedure 

Procedure stampNode ( Node )
	
	obj = Node.GetObject ();
	obj.LastExchange = CurrentSessionDate ();
	obj.Write ();
	
EndProcedure 

Procedure stage2 ( Tenant, Node )
	
	if ( lastAttempt () ) then
		resetAttempts ();
		finishStage2 ( Tenant );
		return;
	endif;
	update = false;
	exchange ( Node, update );
	stampNode ( Node );
	if ( update ) then
		return;
	else
		delayStage2 ( Tenant );
	endif;
	resetAttempts ();
	
EndProcedure

Function lastAttempt ()
	
	SetPrivilegedMode ( true );
	limit = Metadata.ScheduledJobs.Exchange.RestartCountOnFailure;
	if ( limit < 2 ) then
		return false;
	endif; 
	attempt = 1 + Constants.ExchangeAttempt.Get ();
	if ( attempt = limit ) then
		return true;
	endif; 
	Constants.ExchangeAttempt.Set ( attempt );
	return false;
	
EndFunction 

Procedure resetAttempts ()
	
	SetPrivilegedMode ( true );
	Constants.ExchangeAttempt.Set ( 0 );
	
EndProcedure 

Procedure exchange ( Node, Update ) export
	
	p = new Structure;
	p.Insert ( "Node", Node );
	p.Insert ( "StartUp", true );
	p.Insert ( "Update", false );
	p.Insert ( "ID", "" + new UUID () );
	DataProcessors.ExchangeData.Load ( p );
	Update = p.Update;
	if ( Update ) then
		Connections.LeaveMeAlone ();
		DataProcessors.UpdateConfiguration.Run ( p.ID );
	else
		DataProcessors.ExchangeData.Unload ( p );
	endif;
	
EndProcedure

Procedure SendEMail ( AccountEMailRef, AttachedObjects = Undefined, Theme ) export
	
	if ( ValueIsFilled ( AccountEMailRef ) ) then
		Exchange.SendEMailServer ( AccountEMailRef, AttachedObjects, Theme );	
	endif;	
	
EndProcedure

Procedure SendEMailServer ( AttachedObjects = Undefined, Theme, TextMessage, TableReceivers = Undefined ) export 
	
	profile = MailboxesSrv.SystemProfile ();
	mail = new InternetMail;
	try
		mail.Logon ( profile );	
	except
		Output.ErrorLogonInternetMail ( new Structure ( "ErrorDescription", ErrorDescription () ) );
		return;
	endtry;
	for each receiver in TableReceivers do
		emailMessage = getEmailMessage ( profile.User, receiver, Theme, AttachedObjects, TextMessage );
		emailMessage.To.Add ( receiver.EmailAddress );
		mail.Send ( emailMessage );		
	enddo;
	mail.Logoff ();	
	
EndProcedure

Function getEmailMessage ( User, DataReceiver, Theme, AttachedObjects, TextMessage ) export
	
	emailMessage = new InternetMailMessage;
	emailMessage.SenderName = User;
	emailMessage.Subject = Theme;
	if ( ValueIsFilled ( TextMessage ) ) then
		EmailMessage.Texts.Add ( TextMessage, InternetMailTextType.HTML );
	endif;
	addAttachedObjects ( emailMessage, AttachedObjects );
	return ( emailMessage );
	
EndFunction 

Procedure addAttachedObjects ( EmailMessage, AttachedObjects )
	
	if ( TypeOf ( AttachedObjects ) = Type ( "String" ) ) then
		EmailMessage.Attachments.Add ( AttachedObjects );
	else
		// code ...
	endif; 
	
EndProcedure

Procedure TestConnect ( AccountEMailRef ) export
	
	profile = MailboxesSrv.SystemProfile ();
	mail = new InternetMail;
	try
		mail.Logon ( profile );
		Output.EMailLogonOK ();
		mail.Logoff ();
	except
		Output.ErrorLogonInternetMail ( new Structure ( "ErrorDescription", ErrorDescription () ) );
	endtry;
	
EndProcedure

Procedure WSRead ( Params ) export
	
	proxy = getProxy ( Params );
	Output.ConnectToWS ();	
	error = proxy.Begin ( Params.Node, Params.Description, Params.Incoming, Params.Outgoing, Params.UseClassifiers, Params.IncomingClassifiers, Params.OutgoingClassifiers );
	Params.Result = not error;
	if ( error ) then
		return;
	endif;
	Output.ReadWS ();
	data = proxy.Read ( Params.Node );
	binary = data.Get ();
	binary.Write ( Params.Path );
	
EndProcedure

Function getProxy ( Params )
	
	address = Params.WebService + "/" + Params.Tenant + "/ws/ws2.1cws?wsdl";
	definitions = new WSDefinitions ( address, Params.User, Params.Password );
	uri = wsExchange ();
	proxy = new WSProxy ( definitions, URI, "Exchange", "ExchangeSoap" );
	proxy.User = Params.User;
	proxy.Password = Params.Password;
	return proxy;
	
EndFunction

Function wsExchange ()
    
    return "http://localhost/ws2";
    
EndFunction

Procedure WSWrite ( Params ) export 	
	
	proxy = getProxy ( Params );
	Output.ConnectToWS ();
	error = proxy.Begin ( Params.Node, Params.Description, Params.Incoming, Params.Outgoing, Params.UseClassifiers, Params.IncomingClassifiers, Params.OutgoingClassifiers );
	Params.Result = not error;
	if ( error ) then
		return;
	endif;
	Output.WriteWS ();
	binData = new BinaryData ( Params.Path );
	data = new ValueStorage ( binData, new Deflation ( 9 ) );
	proxy.Write ( Params.Node, data, Params.FileExchange );
	
EndProcedure
