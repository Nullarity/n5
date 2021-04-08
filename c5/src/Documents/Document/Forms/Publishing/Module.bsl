// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	restoreNotification ();
	setStatus ();
	fillSubscription ();
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|SendNotification enable SubscribersExist;
	|Subscription enable SendNotification;
	|Comment mark Status = Enum.DocumentStatuses.Editing;
	|Comment enable ( Status = Enum.DocumentStatuses.Editing or SendNotification )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure restoreNotification ()
	
	SendNotification = CommonSettingsStorage.Load ( Enum.SettingsDocumentsSendNotification () );
	
EndProcedure 

&AtServer
Procedure setStatus ()
	
	Status = Parameters.Status;
	
EndProcedure 

&AtServer
Procedure fillSubscription ()
	
	SubscribersExist = Parameters.Subscribers.Count () > 0;
	for each item in Parameters.Subscribers do
		Subscription.Add ( item.Value, "" + item.Value, true );
	enddo; 
	
EndProcedure 

&AtServer
Procedure FillCheckProcessingAtServer ( Cancel, CheckedAttributes )
	
	checkComment ( CheckedAttributes );
	
EndProcedure

&AtServer
Procedure checkComment ( CheckedAttributes )
	
	if ( Status = Enums.DocumentStatuses.Editing ) then
		CheckedAttributes.Add ( "Comment" );
	endif; 
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure Publish ( Command )
	
	if ( not CheckFilling () ) then
		return;
	endif; 
	result = new Structure ( "Subscribers, Comment", getSubscribers (), Comment );
	Close ( result );
	
EndProcedure

&AtClient
Function getSubscribers ()
	
	subscribers = new Array ();
	if ( SendNotification ) then
		for each item in Subscription do
			if ( item.Check ) then
				subscribers.Add ( item.Value );
			endif; 
		enddo; 
	endif; 
	return ? ( subscribers.Count () = 0, undefined, subscribers );
	
EndFunction 

&AtClient
Procedure SendNotificationOnChange ( Item )
	
	applyNotification ();
	
EndProcedure

&AtServer
Procedure applyNotification ()
	
	LoginsSrv.SaveSettings ( Enum.SettingsDocumentsSendNotification (), , SendNotification );
	Appearance.Apply ( ThisObject, "SendNotification" );
	
EndProcedure 

&AtClient
Procedure MarkAll ( Command )
	
	Subscription.FillChecks ( true );
	
EndProcedure

&AtClient
Procedure UnmarkAll ( Command )

	Subscription.FillChecks ( false );
	
EndProcedure
