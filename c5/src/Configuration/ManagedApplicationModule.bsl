var LaunchParameters export;
var LoggedUser export;
var CurrentCompany export;
var MailIsOpen export;
var MSIE export;
var DocumentsCurrentRow export;
var DocumentsFindBook export;
var TemporaryFolder export;
var TimeShift;
var SessionInfo export;
var FrameworkVersion export;
var FirstTimeUpdateCheck export;

Procedure BeforeStart ( Cancel )
	
	init ();
	loadParameters ();
	if ( LaunchParameters [ Enum.LaunchParametersMode () ] = Enum.LaunchParametersUpdateApplied () ) then
		StartingSrv.AcceptUpdate ();
	endif;
	initOptions ();
	
EndProcedure

Procedure init ()
	
	si = new SystemInfo ();
	FrameworkVersion = si.AppVersion;
	FirstTimeUpdateCheck = true;
	
EndProcedure

Procedure loadParameters ()
	
	LaunchParameters = new Map ();
	if ( LaunchParameter = "" ) then
		return;
	endif; 
	LaunchParameters = Conversion.ParametersToMap ( LaunchParameter );
	
EndProcedure 

Procedure initOptions ()
	
	if ( Logins.Rooted () ) then
		return;
	endif;
	set = new Structure ();
	set.Insert ( "Visibility", false );
	set.Insert ( "Button", 0 );
	#if ( WebClient ) then
		computer = "WebClient";
		webClient = true;
	#else
		webClient = false;
		computer = ComputerName ();
	#endif
	#if ( MobileClient ) then
		mobileClient = true;
	#else
		mobileClient = false;
	#endif
	#if ( ThinClient ) then
		thinClient = true;
	#else
		thinClient = false;
	#endif
	#if ( ThickClientManagedApplication ) then
		thickClient = true;
	#else
		thickClient = false;
	#endif
	linux = Framework.IsLinux ();
	set.Insert ( "Session", StartingSrv.NewSession ( computer, webClient, mobileClient, thinClient, thickClient, linux ) );
	SetInterfaceFunctionalOptionParameters ( set );
	
EndProcedure 

Procedure OnStart ()

	if ( initNode () ) then
		Exit ( false );
		return;
	endif;
	SessionInfo = StartingSrv.SessionInfo ();
	MailIsOpen = false;
	if ( SessionInfo.Rooted ) then
		Starting.Unlockdb ();
		openTenants ();
		return;
	endif;
	Starting.Go ();
	AttachEmailCheck ();
	AttachIdleHandler ( "runMainScenario", 1, true );
	
EndProcedure

Function initNode ()
	
	if ( LaunchParameters [ Enum.LaunchParametersInitNode () ] <> undefined ) then
		StartingSrv.InitNode ();
		return true;
	endif;
	return false;
	
EndFunction

Procedure runMainScenario () export
	
	#if ( ThinClient or ThickClientManagedApplication ) then
		port = LaunchParameters [ Enum.LaunchParametersRunMainScenario () ];
		if ( port = undefined ) then
			return;
		endif;
		try
			connector = Eval ( "new TestedApplication ( ""localhost"", " + port + " )" );
			connector.Connect ();
			button = connector.FindObject ( Type ( "TestedFormButton" ), , "FormCatalogScenariosRun", 3 );
			button.Click ();
			connector.Disconnect ();
		except
			return;
		endtry;
	#endif
	
EndProcedure

Procedure openTenants ()
	
	OpenForm ( "Catalog.Tenants.Form.Activation", new Structure ( "ForceActivation", true ) );
	
EndProcedure

Procedure StartUpdatesChecking () export
	
	StopUpdatesChecking ();
	StartingSrv.CheckUpdates ( FirstTimeUpdateCheck );
	FirstTimeUpdateCheck = false;
	AttachIdleHandler ( "_checkUpdates", 10, true );
	
EndProcedure

Procedure _checkUpdates () export
	
	if ( ApplicationUpdatesSrv.NewUpdates () ) then
		if ( not SessionInfo.NewUpdates ) then
			OpenForm ( "DataProcessor.Updates.Form" );
		endif;
	else
		manuallyUpdated = SessionInfo.NewUpdates;
		if ( manuallyUpdated ) then
			SessionInfo.NewUpdates = false;
			RefreshInterface ();
		endif;
		AttachIdleHandler ( "StartUpdatesChecking", Enum.ConstantsUpdateCheckingPeriod (), true );
	endif;
	
EndProcedure

Procedure StopUpdatesChecking () export
	
	DetachIdleHandler ( "StartUpdatesChecking" );
	DetachIdleHandler ( "_checkUpdates" );
	
EndProcedure

Procedure AttachEmailCheck () export
	
	detachCheckEmail ();
	detachShowEmail ();
	periodicity = MailChecking.GetPeriodicity ();
	if ( periodicity = undefined ) then
		return;
	endif; 
	_checkEmail ();
	attachCheckEmail ( periodicity );
	
EndProcedure 

Procedure detachCheckEmail ()
	
	DetachIdleHandler ( "_checkEmail" );
	
EndProcedure 

Procedure detachShowEmail ()
	
	DetachIdleHandler ( "_showEmail" );
	
EndProcedure 

Procedure attachCheckEmail ( Timer )
	
	AttachIdleHandler ( "_checkEmail", Timer );
	
EndProcedure 

Procedure _checkEmail () export
	
	detachShowEmail ();
	MailChecking.Start ();
	attachShowEmail ( 15 );
	
EndProcedure 

Procedure attachShowEmail ( Timer )
	
	AttachIdleHandler ( "_showEmail", Timer, true );
	
EndProcedure 

Procedure _showEmail () export
	
	status = MailChecking.GetResult ();
	if ( status.Complete ) then
		if ( status.Count > 0 ) then
			if ( status.ErrorCode = 0 ) then
				Output.NewEmails ( new Structure ( "Message", status.Message ), "e1cib/command/DataProcessor.EmailClient.Command.Mail", PictureLib.Info32 );
			endif; 
			if ( MailIsOpen ) then
				Notify ( Enum.MessageNewMail () );
			else
				SetAppCaption ( status.Total );
			endif; 
		endif; 
		if ( status.ErrorCode = 1 ) then
			Output.NewEmails ( new Structure ( "Message", status.Message ), "e1cib/command/DataProcessor.EmailClient.Command.Mail", PictureLib.Warning );
		elsif ( status.ErrorCode = 2 ) then
			Output.NewEmails ( new Structure ( "Message", status.Message ), GetURL ( status.OutgoingEmail ), PictureLib.Warning );
		endif;
	else
		attachShowEmail ( 30 );
	endif; 
	
EndProcedure 

Procedure SetAppCaption ( UnreadEmails = 0 ) export
	
	parts = new Array ();
	if ( UnreadEmails > 0 ) then
		parts.Add ( Format ( UnreadEmails, "NG=" ) );
	endif; 
	if ( CurrentCompany = undefined ) then
		CurrentCompany = StartingSrv.CurrentCompany ();
	endif;
	if ( CurrentCompany <> "" ) then
		parts.Add ( CurrentCompany );
	endif; 
	parts.Add ( LoggedUser );
	parts.Add ( Output.MetadataPresentation () );
	ClientApplication.SetCaption ( StrConcat ( parts, "." ) );
	
EndProcedure 

Procedure UpdateAppCaption () export
	
	CurrentCompany = undefined;
	SetAppCaption ();
	
EndProcedure 

Function IsMSIE () export
	
	if ( Framework.VersionLess ( "8.3.14" ) ) then
		if ( MSIE = undefined ) then
			si = new SystemInfo ();
			MSIE = ( si.UserAgentInformation = "" ) or ( Find ( si.UserAgentInformation, "MSIE" ) > 0 );
		endif; 
		return MSIE;
	else
		return false;
	endif;

EndFunction

Function SessionDate ( Date = undefined ) export
	
	currentDate = CurrentDate ();
	if ( TimeShift = undefined ) then
		TimeShift = 60 * Round ( ( PeriodsSrv.GetCurrentSessionDate () - currentDate ) / 60 );
	endif; 
	return ? ( Date = undefined, currentDate, Date ) + TimeShift;
	
EndFunction 

Procedure DemoSessionWarning1 () export
	
	showWarning ( 1 );
	
EndProcedure

Procedure showWarning ( Stage )
	
	//@skip-warning
	OpenForm ( "CommonForm.DemoVersion", new Structure ( "Stage", Stage ), , , , ,
		new NotifyDescription ( "DemoSessionExpired", Starting, Stage ) );

EndProcedure

Procedure DemoSessionWarning2 () export
	
	showWarning ( 2 );
	
EndProcedure

Procedure ErrorDisplayProcessing ( ErrorInfo, SessionTerminationRequired, StandardProcessing )
	
	id = ErrorInfo.Description;
	if ( id = Enum.ExceptionsUndefinedFilesFolder () ) then
		StandardProcessing = false;
		Output.SelectFilesFolder ( Attachments );
	endif;
	
EndProcedure
