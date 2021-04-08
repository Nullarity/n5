
Function GetCopies () export
	
	if ( IsDemo () ) then
		return undefined;
	endif;
	sessions = new Array ();
	copies = getSessions ( "Copies" );
	for each session in copies do
		sessions.Add ( presentation ( session ) );
	enddo; 
	return ? ( sessions.Count () = 0, undefined, sessions );
	
EndFunction 

Function IsDemo () export
	
	code = Lower ( TrimR ( DF.Pick ( SessionParameters.Tenant, "Code" ) ) );
	return code = "demo";
	
EndFunction 

Function getSessions ( Filter )
	
	SetPrivilegedMode ( true );
	credentials = getCredentials ();
	mySession = InfoBaseSessionNumber ();
	myName = UserName ();
	mydb = getIBName ();
	localhost = ComputerName ();
	connector = new COMObject ( "V83.COMConnector" );
	ragent = connector.ConnectAgent ( getConnection () );
	ragent.AuthenticateAgent ( credentials.ServerAdministrator, credentials.ServerPassword );
	clusters = ragent.GetClusters ();
	sessions = new Array ();
	stop = false;
	for each cluster in clusters do
		ragent.Authenticate ( cluster, credentials.ClusterAdministrator, credentials.ClusterPassword );
		ibases = ragent.GetInfoBases ( cluster );
		for each ibase in ibases do
			if ( Lower ( ibase.Name ) = mydb ) then
				ibSessions = ragent.GetInfoBaseSessions ( cluster, ibase );
				for each session in ibSessions do
					if ( session.Hibernate ) then
						continue;
					endif;
					if ( Filter = "All" ) then
						found = true;
					elsif ( Filter = "LeaveMeAlone" ) then
						found = ( session.SessionID <> mySession );
					elsif ( Filter = "Me" ) then
						found = ( session.SessionID = mySession );
						stop = found;
					elsif ( Filter = "Copies" ) then
						found = ( session.SessionID <> mySession )
						and ( session.Host <> localhost )
						and ( session.UserName = myName );
					endif; 
					if ( found ) then
						if ( Find ( "1cv8, 1cv8c, webclient, designer, comconnection, wsconnection, backgroundjob", Lower ( Session.AppID ) ) > 0 ) then
							sessions.Add ( session );
						endif;
						if ( stop ) then
							return sessions;
						endif; 
					endif; 
				enddo; 
			endif; 
		enddo; 
	enddo; 
	return sessions;
	
EndFunction

Procedure DisconnectCopies () export
	
	disconnect ( "Copies" );
	
EndProcedure

Procedure DisconnectMe () export
	
	disconnect ( "Me" );
	
EndProcedure

Procedure DisconnectAll () export
	
	disconnect ( "All" );
	
EndProcedure

Procedure LeaveMeAlone () export
	
	disconnect ( "LeaveMeAlone" );
	
EndProcedure

Function presentation ( Session )
	
	p = new Structure ();
	p.Insert ( "ComputerName", Session.Host );
	p.Insert ( "SessionStarted", Session.StartedAt );
	s = Output.SessionPresentation ( p );
	return s;
	
EndFunction 

Procedure disconnect ( Filter )
	
	sessions = getSessions ( Filter );
	if ( sessions.Count () = 0 ) then
		return;
	endif;
	selection = new Array ();
	for each session in sessions do
		selection.Add ( session.SessionID );
	enddo; 
	kill ( selection );
	
EndProcedure

Procedure kill ( Sessions )
	
	SetPrivilegedMode ( true );
	credentials = getCredentials ();
	mydb = getIBName ();
	connector = new COMObject ( "V83.COMConnector" );
	ragent = connector.ConnectAgent ( getConnection () );
	ragent.AuthenticateAgent ( credentials.ServerAdministrator, credentials.ServerPassword );
	clusters = ragent.GetClusters ();
	for each cluster in clusters do
		ragent.Authenticate ( cluster, credentials.ClusterAdministrator, credentials.ClusterPassword );
		ibases = ragent.GetInfoBases ( cluster );
		for each ibase in ibases do
			if ( Lower ( ibase.Name ) = mydb ) then
				ibSessions = ragent.GetInfoBaseSessions ( cluster, ibase );
				for each session in ibSessions do
					if ( Sessions.Find ( session.SessionID ) = undefined ) then
						continue;
					endif; 
					ragent.TerminateSession ( cluster, session );
				enddo; 
			endif; 
		enddo; 
	enddo; 
	SetPrivilegedMode ( false );
	
EndProcedure 

Function getCredentials ()
	
	s = "
	|select Constants.ClusterAdministrator as ClusterAdministrator, Constants.ClusterPassword as ClusterPassword,
	|	Constants.ServerAdministrator as ServerAdministrator, Constants.ServerPassword as ServerPassword,
	|	Constants.CloudUser as CloudUser, Constants.CloudPassword as CloudPassword
	|from Constants as Constants
	|";
	q = new Query ( s );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction 

Function getIBName ()
	
	s = InfoBaseConnectionString ();
	a = Find ( s, "Ref=""" );
	ibName = Mid ( s, a + 5 );
	a = Find ( ibName, """" );
	ibName = Left ( ibName, a - 1 );
	return Lower ( ibName );
	
EndFunction 

Function getConnection ()
	
	address = Constants.Agent.Get ();
	if ( address = "" ) then
		address = NStr ( InfobaseConnectionString (), "Srvr" );
	endif;
	return address;
	
EndFunction 

Procedure Lock () export
	
	SetPrivilegedMode ( true );
	start = CurrentDate ();
	period = Enum.ConstantsUpdateLockingPeriod ();
	end = start + period;
	notification = Output.InfobaseUpdateMessage ( new Structure ( "Period, Date", period / 60, start ) );
	password = Constants.ServerCode.Get ();
	if ( fileMode () ) then
		lock = new SessionsLock ();
		lock.Begin = start;
		lock.End  = start + period;
		lock.KeyCode = password;
		lock.Message = notification;
		lock.Use = true;
		splitted = SessionParameters.TenantUse;
		SessionParameters.TenantUse = false;
		SetSessionsLock ( lock );
		SessionParameters.TenantUse = splitted;
	else
		mydb = undefined;
		myProcess = undefined;
		findMe ( mydb, myProcess );
		if ( mydb <> undefined ) then
			start = CurrentDate ();
			mydb.DeniedFrom = start;
			mydb.DeniedTo = end;
			mydb.DeniedMessage = notification;
			mydb.PermissionCode = password;
			mydb.SessionsDenied = true;
			Constants.JobsDisabled.Set ( mydb.ScheduledJobsDenied );
			mydb.ScheduledJobsDenied = true;
			myProcess.UpdateInfoBase ( mydb );
		endif;
	endif;
	
EndProcedure

Function fileMode ()
	
	return StrFind ( Lower ( InfoBaseConnectionString () ), "file=" ) > 0;
	
EndFunction

Procedure findMe ( FoundDB, FoundProcess )
	
	credentials = getCredentials ();
	mydb = getIBName ();
	connector = new COMObject ( "V83.COMConnector" );
	agent = getConnection ();
	ragent = connector.ConnectAgent ( agent );
	ragent.AuthenticateAgent ( credentials.ServerAdministrator, credentials.ServerPassword );
	clusters = ragent.GetClusters ();
	for each cluster in clusters do
		ragent.Authenticate ( cluster, credentials.ClusterAdministrator, credentials.ClusterPassword );
		processes = ragent.GetWorkingProcesses ( cluster );
		for each processInfo in processes do
			if ( processInfo.Running and processInfo.IsEnable ) then
				connection = processInfo.HostName + ":" + Format ( processInfo.MainPort, "NG=" );
				process = connector.ConnectWorkingProcess ( connection );
				process.AuthenticateAdmin ( credentials.ClusterAdministrator, credentials.ClusterPassword );
				process.AddAuthentication ( credentials.CloudUser, credentials.CloudPassword );
				ibases = process.GetInfoBases ();
				for each ibase in ibases do
					if ( Lower ( ibase.Name ) = mydb ) then
						FoundProcess = process;
						FoundDB = ibase;
						return;
					endif;
				enddo; 
			endif;
		enddo;
	enddo;
	
EndProcedure

Procedure Unlock () export 
	
	SetPrivilegedMode ( true );
	if ( fileMode () ) then
		splitted = SessionParameters.TenantUse;
		SessionParameters.TenantUse = false;
		lock = new SessionsLock ();
		SetSessionsLock ( lock );
		SessionParameters.TenantUse = splitted;
	else
		mydb = undefined;
		myprocess = undefined;
		findMe ( mydb, myprocess );
		if ( mydb <> undefined ) then
			emptyDate = Date ( 1, 1, 1 );
			mydb.DeniedFrom = emptyDate;
			mydb.DeniedTo = emptyDate;
			mydb.DeniedMessage = "";
			mydb.PermissionCode = "";
			mydb.SessionsDenied = false;
			mydb.ScheduledJobsDenied = Constants.JobsDisabled.Get ();
			myprocess.UpdateInfoBase ( mydb );
		endif;
	endif;
	
EndProcedure
