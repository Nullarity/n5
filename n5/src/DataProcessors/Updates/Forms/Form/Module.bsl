&AtClient
var ConnectionString;
&AtClient
var ServerMode;
&AtClient
var ComInstalled;
&AtClient
var DesignerExists;
&AtClient
var UpdaterFolder;
&AtClient
var UpdaterZIP;
&AtClient
var PathSeparator;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	init ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|NewUpdatesPicture NewUpdatesAvailable FormInstall FormDownload show NewUpdatesExist;
	|FormCheckUpdates show not NewUpdatesExist;
	|FormEnableChecking WarningPicture UpdatesAreDisabled show not CheckUpdates;
	|SuccessPicture UpdatesInstalled show not NewUpdatesExist;
	|FormCustomNotes show filled ( CustomNotes )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure init ()
	
	UpdaterName = updaterName ();
	RootUser = Cloud.User ();
	ApplicationName = Metadata.Name;
	License = Constants.License.Get ();
	CheckUpdates = Constants.CheckUpdates.Get ();
	MetadataVersion = Metadata.Version;
	CurrentVersion = CoreLibrary.VersionToNumber ( Metadata.Version );
	ServerCode = Constants.ServerCode.Get ();
	Backup = Constants.Backup.Get ();
	info = new SystemInfo ();
	PlatformVersion = CoreLibrary.VersionToNumber ( info.AppVersion );
	Tenant = DF.Pick ( SessionParameters.Tenant, "Code" );
	TenantUse = SessionParameters.TenantUse;
	
EndProcedure

&AtServerNoContext
Function updaterName ()
	
	return Metadata.DataProcessors.Updates.Templates [ 0 ].Name;
	
EndFunction

&AtServer
Function trulyNew ()
	
	exists = CurrentVersion < LastRelease;
	Constants.NewUpdates.Set ( exists );
	return exists;
	
EndFunction

&AtClient
Procedure OnOpen ( Cancel )
	
	#if ( WebClient ) then
		Items.Pages.CurrentPage = Items.WebClient;
	#else
		initUpdater ();
		StopUpdatesChecking ();
		fixBackup ();
		AttachIdleHandler ( "checkForUpdates", 0.1, true );
	#endif
	
EndProcedure

&AtClient
Procedure fixBackup ()
	
	if ( Backup = "" ) then
		BeginGettingDocumentsDir ( new NotifyDescription ( "UserFolder", ThisObject ) );
	endif;
	
EndProcedure

&AtClient
Procedure UserFolder ( Folder, Params ) export
	
	Backup = Folder + ApplicationName + "Backup";
		
EndProcedure

&AtClient
Procedure initUpdater ()
	
	PathSeparator = GetPathSeparator ();
	ConnectionString = InfoBaseConnectionString ();
	ComInstalled = false;
	ServerMode = StrFind ( Lower ( ConnectionString ), "srvr=" ) > 0;
	if ( ServerMode ) then
		try
			#if ( not MobileClient and not WebClient ) then
				//@skip-warning
				connector = new COMObject ( "V83.COMConnector" );
			#endif
			ComInstalled = true;
		except
		endtry;
	endif;
	
EndProcedure

&AtClient
Procedure checkForUpdates () export
	
	var error;
	
	data = ApplicationUpdates.LastVersion ( error );
	if ( data = undefined ) then
		Output.ShowError ( ThisObject, , Output.RequestError () + Chars.LF + error );
	else
		Items.Pages.CurrentPage = Items.Information;
		stampRelease ( data );
	endif;
	
EndProcedure

&AtClient
Procedure ShowError ( Params ) export
	
	Close ();
	
EndProcedure

&AtServer
Procedure stampRelease ( val Data )
	
	LastRelease = Data.Release;
	LastCompatibility = Data.Compatibility;
	LastIssued = Date ( 1, 1, 1 ) + Data.Date;
	CustomNotes = data.ReleaseNotes;
	NewUpdatesExist = trulyNew ();
	Appearance.Apply ( ThisObject, "NewUpdatesExist" );
	Appearance.Apply ( ThisObject, "CustomNotes" );
	
EndProcedure

&AtClient
Procedure OnClose ( Exit )
	
	if ( not Exit ) then
		if ( CheckUpdates
			and not NewUpdatesExist ) then
			StartUpdatesChecking ();
		endif;
	endif;

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ReleaseNotes ( Command )
	
	OpenHelp ( "DataProcessor.UpdateInfobase" );
	
EndProcedure

&AtClient
Procedure CustomNotes ( Command )
	
	BeginRunningApplication ( new NotifyDescription ( "BrowserOpened", ThisObject ), CustomNotes );
	
EndProcedure

&AtClient
Procedure BrowserOpened ( Result, Params ) export
	
	//@skip-warning
	nothing = true;
	
EndProcedure

&AtClient
Procedure Install ( Command )
	
	#if ( not WebClient ) then
		LocalFiles.SetTempFolder ( new NotifyDescription ( "PrepareUpdater", ThisObject ) );
	#endif
	
EndProcedure

#if ( not WebClient ) then
	
&AtClient
Procedure PrepareUpdater ( OK, Params ) export
	
	file = BinDir () + "1cv8";
	if ( Framework.IsWindows () ) then
		file = file + ".exe";
	endif;
	LocalFiles.CheckExistence ( file, new NotifyDescription ( "CheckingExistence1cv8", ThisObject ) );
	
EndProcedure

&AtClient
Procedure CheckingExistence1cv8 ( Exists, Params ) export
	
	DesignerExists = Exists;
	if ( DesignerExists ) then
		UpdaterFolder = TemporaryFolder + PathSeparator + ApplicationName + "_" + UpdaterName;
		LocalFiles.CheckExistence ( UpdaterFolder, new NotifyDescription ( "UpdaterExists", ThisObject ) );
	else
		continueInstallation ();
	endif;
	
EndProcedure

&AtClient
Procedure UpdaterExists ( Exists, Params ) export
	
	if ( Exists ) then
		continueInstallation ();
	else
		LocalFiles.CreateFolder ( UpdaterFolder, new NotifyDescription ( "UnloadUpdater", ThisObject ) );
	endif;
	
EndProcedure

&AtClient
Procedure UnloadUpdater ( Result, Params ) export
	
	//@skip-warning
	data = getUpdater ();
	UpdaterZIP = UpdaterFolder + GetPathSeparator () + "db.zip";
	data.BeginWrite ( new NotifyDescription ( "UnzipUpdater", ThisObject ), UpdaterZIP );
	
EndProcedure

&AtServerNoContext
Function getUpdater ()
	
	name = updaterName ();
	archive = DataProcessors.Updates.GetTemplate ( name );
	return archive;
	
EndFunction

&AtClient
Procedure UnzipUpdater ( Params ) export
	
	#if ( not MobileClient and not WebClient ) then
		zip = new ZipFileReader ( UpdaterZIP );
		zip.ExtractAll ( UpdaterFolder );
		continueInstallation ();
	#endif
	
EndProcedure

&AtClient
Procedure continueInstallation ()
	
	if ( masterNode ()
		and directConnection ()
		and designerFound ()
		and credentialsDefined () ) then
		checkForUpdates ();
		if ( NewUpdatesExist ) then
			if ( licenseValid ()
				and updateCompatible () ) then
				file = downloaded ();
				LocalFiles.CheckExistence ( file, new NotifyDescription ( "CheckUpdateExistence", ThisObject, file ) );
			endif;
		else
			Output.UpdatesNotFound ();
		endif;
	endif;
	
EndProcedure

&AtClient
Function masterNode ()
	
	if ( SessionInfo.Master ) then
		return true;
	else
		Output.MasterNodeRequired ();
		return false;
	endif;
	
EndFunction
	
&AtClient
Function directConnection ()
	
	direct = StrFind ( Lower ( ConnectionString ), "ws=" ) = 0;
	if ( direct ) then
		return true;
	else
		Output.DirectConnectionRequired ();
		return false;
	endif;
	
EndFunction

&AtClient
Function designerFound ()
	
	if ( DesignerExists ) then
		return true;
	else
		Output.DesignerNotFound ();
		return false;
	endif;
	
EndFunction

&AtClient
Function credentialsDefined ()
	
	if ( not ServerMode ) then
		return true;
	endif;
	if ( rootDefined () ) then
		return true;
	else
		Output.UndefinedCloudUser ();
		return false;
	endif;
	
EndFunction

&AtClient
Function rootDefined ()
	
	return RootUser <> "";
	
EndFunction

&AtClient
Function licenseValid ()
	
	id = ApplicationUpdatesSrv.License ();
	if ( id = "" ) then
		return true;
	endif;
	error = undefined;
	expired = ApplicationUpdates.SubscriptionExpired ( id, error );
	if ( expired = undefined ) then
		raise error;
	endif;
	if ( expired < LastIssued ) then
		p = new Structure ( "Expired, Issued" );
		p.Expired = Format ( expired, "DLF=D" );
		p.Issued = Format ( expired, "DLF=D" );
		Output.LicenseExpired ( , , p );
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Function updateCompatible ()
	
	if ( PlatformVersion < LastCompatibility ) then
		p = new Structure ( "RequiredVersion, YourVersion" );
		p.RequiredVersion = CoreLibrary.NumberToVersion ( LastCompatibility );
		p.YourVersion = CoreLibrary.NumberToVersion ( PlatformVersion );
		Output.PlatformNotSupported ( , , p );
		return false;
	endif;
	return true;
	
EndFunction

&AtClient
Function downloaded ()
	
	name = Enum.ConstantsApplicationCode () + "_" + StrReplace ( CoreLibrary.NumberToVersion ( LastRelease ), ".", "_" ) + ".cfu";
	return TemporaryFolder + PathSeparator + name;
	
EndFunction

&AtClient
Procedure CheckUpdateExistence ( Exists, File ) export
	
	if ( Exists ) then
		startUpdate ( File )
	else
		downloadUpdate ( File, new NotifyDescription ( "BeginUpdate", ThisObject ) );
	endif;

EndProcedure

&AtClient
Procedure startUpdate ( File )
	
	Output.InfobaseWillBeLocked ( ThisObject, File, new Structure ( "Key", ServerCode ) );
		
EndProcedure

&AtClient
Procedure downloadUpdate ( File, Callback )
	
	connection = new HTTPConnection ( "www.mycont.md" );
	request = new HTTPRequest ( "/ls/hs/Version/Download?Application=" + Enum.ConstantsApplicationCode () + "&Version=" + Format ( LastRelease, "NG=" ) + "&License=" + License );
	try
		response = Connection.Get ( request );
	except
		reportProblem ( ErrorDescription () );
		return;
	endtry;
	if ( not goodResponse ( response ) ) then
		reportProblem ( response.GetBodyAsString () );
		return;
	endif;
	data = response.GetBodyAsBinaryData ();
	p = new Structure ( "File, Callback", File, Callback );
	data.BeginWrite ( new NotifyDescription ( "UpdateDownloaded", ThisObject, p ), File );

EndProcedure

&AtClient
Function goodResponse ( Response )
	
	return Response.StatusCode = 200;
	
EndFunction

&AtClient
Procedure reportProblem ( Error )
	
	raise Output.RequestError () + ":" + Chars.LF + Error;
	
EndProcedure

&AtClient
Procedure UpdateDownloaded ( Params ) export
	
	ExecuteNotifyProcessing ( Params.Callback, Params.File );

EndProcedure

&AtClient
Procedure BeginUpdate ( File, Params ) export
	
	startUpdate ( File );

EndProcedure

&AtClient
Procedure InfobaseWillBeLocked ( Answer, File ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	if ( ServerMode
		and not ComInstalled ) then
		Output.V83ComError ();
		return;
	endif;
	inUse = lockdb ();
	if ( inUse ) then
		OpenForm ( "DataProcessor.Updates.Form.Disconnection", new Structure ( "ServerMode", ServerMode ), ThisObject, , , , new NotifyDescription ( "Disconnection", ThisObject, File ) );
	else
		runUpdater ( File );
	endif;
	
EndProcedure

&AtServerNoContext
Function lockdb ()
	
	Connections.Lock ();
	return not alone ();

EndFunction

&AtServerNoContext
Function alone ()
	
	SessionParameters.TenantUse = false;
	alone = GetInfoBaseSessions ().Count () = 1;
	SessionParameters.TenantUse = true;
	return alone;

EndFunction

&AtClient
Procedure runUpdater ( File )

	#if ( not MobileClient ) then
		runner = getRunner ();
		p = new Structure ();
		p.Insert ( "Runner", runner );
		p.Insert ( "Connection", ConnectionString );
		p.Insert ( "Update", File );
		p.Insert ( "User", RootUser );
		p.Insert ( "CurrentUser", UserName () );
		p.Insert ( "Key", ServerCode );
		p.Insert ( "Backup", Backup );
		p.Insert ( "Tenant", Tenant );
		p.Insert ( "TenantUse", TenantUse );
		params = escapeString ( Conversion.ToJSON ( p ) );
		command = " /N " + CurrentLanguage () + " /IBConnectionString ""File='" + UpdaterFolder + "';"" /C """ + params + """";
		if ( Framework.IsWindows () ) then
			System ( """start """" " + runner + command + """" );
		else
			System ( runner + command + " &" );
		endif;
		Exit ( false );
	#endif

EndProcedure

&AtClient
Function getRunner ()
	
	#if ( ThinClient ) then
		file = "1cv8c";
	#else
		file = "1cv8";
	#endif
	if ( Framework.IsWindows () ) then
		file = file + ".exe";
	endif;
	return """" + BinDir () + file + """";
	
EndFunction

&AtClient
Function escapeString ( Params )
	
	s = StrReplace ( Params, """", "#0#7#" );
	s = StrReplace ( s, "/", "#0#8#" );
	s = StrReplace ( s, "\", "#0#9#" );
	return s;
	
EndFunction

&AtClient
Procedure Disconnection ( Result, File ) export
	
	if ( Result = undefined ) then
		unlockdb ();
	else
		runUpdater ( File );
	endif;

EndProcedure

&AtServerNoContext
Procedure unlockdb ()
	
	Connections.Unlock ();
	
EndProcedure

#endif

&AtClient
Procedure DontCheck ( Command )
	
	CheckUpdates = false;
	StopUpdatesChecking ();
	disableChecking ();
	RefreshInterface ();
	Close ();
	
EndProcedure

&AtServerNoContext
Procedure disableChecking ()
	
	Constants.NewUpdates.Set ( false );
	Constants.CheckUpdates.Set ( false );
	
EndProcedure

&AtClient
Procedure Download ( Command )
	
	#if ( not WebClient ) then
		LocalFiles.SetTempFolder ( new NotifyDescription ( "PrepareDownloading", ThisObject ) );
	#endif
	
EndProcedure

&AtClient
Procedure PrepareDownloading ( OK, Params ) export
	
	#if ( not WebClient ) then
		checkForUpdates ();
		if ( NewUpdatesExist ) then
			downloadUpdate ( downloaded (), new NotifyDescription ( "SaveFile", ThisObject ) );
		else
			Output.UpdatesNotFound ();
		endif;
	#endif
	
EndProcedure

&AtClient
Procedure SaveFile ( File, Params ) export
	
	dialog = new FileDialog ( FileDialogMode.Save );
	dialog.FullFileName = FileSystem.GetFileName ( File );
	dialog.Show ( new NotifyDescription ( "SaveUpdate", ThisObject, File ) );
	
EndProcedure

&AtClient
Procedure SaveUpdate ( Destination, Source ) export
	
	if ( Destination = undefined ) then
		return;
	endif;
	BeginCopyingFile ( new NotifyDescription ( "SavingCompleted", ThisObject ), Source, Destination [ 0 ] );
	
EndProcedure

&AtClient
Procedure SavingCompleted ( Result, Params ) export
	
	Output.UpdateSaved ();
	
EndProcedure

&AtClient
Procedure CheckUpdates ( Command )
	
	checkForUpdates ();
	
EndProcedure

&AtClient
Procedure InstallUpdateConfirmation ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.No ) then
		return;
	endif;
	
EndProcedure

&AtClient
Procedure EnableChecking ( Command )
	
	CheckUpdates = true;
	startChecking ();
	Close ();
	
EndProcedure

&AtServerNoContext
Procedure startChecking ()
	
	Constants.CheckUpdates.Set ( true );
	
EndProcedure
