&AtClient
var StayOpen;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readVersion ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readVersion ()
	
	AppVersion = Metadata.Version;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|GroupCloud GroupMail SaaS show Object.Cloud;
	|GroupSaaS show Object.SaaS;
	|ProxyServer ProxyPort enable Object.UseProxy = 2;
	|ProxyUser ProxyPassword enable Object.UseProxy <> 0
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	if ( not checkCloudSaaS () ) then
		Cancel = true;
	endif;
	
EndProcedure

&AtServer
Function checkCloudSaaS ()
	
	fields = new Array ();
	if ( Object.Cloud ) then
		fields.Add ( "Website" );
		fields.Add ( "Domain" );
		fields.Add ( "ApplicationURL" );
		fields.Add ( "RemoteActionsService" );
		fields.Add ( "FoldersURL" );
	endif;
	if ( Object.SaaS ) then
		fields.Add ( "CloudPaymentMethod" );
		fields.Add ( "CloudUser" );
		fields.Add ( "CloudPassword" );
		fields.Add ( "ForumURL" );
		fields.Add ( "ThinClientURL" );
		fields.Add ( "InfoEmail" );
		fields.Add ( "SupportEmail" );
	endif;
	return Forms.Check ( ThisObject, fields );
	
EndFunction

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( Object.UseProxy = 2 
		and Items.ProxyServer.MarkIncomplete ) then
		Cancel = true;
		Output.ProxyServerNotSet ( , "ProxyServer" );
	endif;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	RefreshReusableValues ();

EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	if ( checkUpdates ()  ) then
		StartUpdatesChecking ();
	endif;
	if ( optionsChanged () ) then
		StayOpen = true;
		Output.RestartInterface ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Function checkUpdates ()
	
	check = Object.CheckUpdates;
	return check
	and check <> CheckUpdates;

EndFunction

&AtClient
Function optionsChanged ()
	
	return CloudOption <> Object.Cloud;
	
EndFunction 

&AtClient
Procedure RestartInterface ( Params ) export
	
	readOptions ();
	RefreshInterface ();
	StayOpen = false;
	Close ();
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	readOptions ();
	
EndProcedure

&AtClient
Procedure readOptions ()
	
	CloudOption = Object.Cloud;
	CheckUpdates = Object.CheckUpdates;
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( StayOpen ) then
		Cancel = true;
	elsif ( Modified ) then
		Cancel = true;
		Output.ConfirmExit ( ThisObject );
	endif; 
	
EndProcedure

&AtClient
Procedure ConfirmExit ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Cancel ) then
		return;
	elsif ( Answer = DialogReturnCode.Yes ) then
		Write ();
	else
		Modified = false;
	endif; 
	Close ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CloudOnChange ( Item )
	
	applyCloud ();
	
EndProcedure

&AtClient
Procedure applyCloud ()
	
	if ( not Object.Cloud ) then
		Object.SaaS = false;
		Appearance.Apply ( ThisObject, "Object.SaaS" );
	endif;
	Appearance.Apply ( ThisObject, "Object.Cloud" );
	
EndProcedure

&AtClient
Procedure SaaSOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.SaaS" );
	
EndProcedure

&AtClient
Procedure FoldersStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	LocalFiles.SelectFolder ( Item );

EndProcedure

&AtClient
Procedure BackupStartChoice ( Item, ChoiceData, StandardProcessing )
	
	StandardProcessing = false;
	LocalFiles.SelectFolder ( Item );
	
EndProcedure

&AtClient
Procedure UseProxyOnChange ( Item )
	
	applyProxyServer ();
	Appearance.Apply ( ThisObject, "Object.UseProxy" );
	
EndProcedure

&AtClient
Procedure applyProxyServer () 

	Items.ProxyServer.AutoMarkIncomplete = ( Object.UseProxy = 2 );

EndProcedure

&AtClient
Procedure ProxyServerOnChange ( Item )
	
	applyProxyServer ();
	
EndProcedure

// *****************************************
// *********** Variables Initialization

#if ( Client ) then
	
StayOpen = false;

#endif
