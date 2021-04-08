&AtClient
var GoogleProjectID;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	setUser ();
	loadUsers ();
	
EndProcedure

&AtServer
Procedure setUser ()
	
	User = "" + SessionParameters.User;
	
EndProcedure 

&AtServer
Procedure loadUsers ()
	
	for each receiver in Parameters.Users do
		Receivers.Add ( receiver, "" + receiver  );
	enddo; 
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	#if ( WebClient ) then
		Output.WebclientIsNotSupported ();
		Cancel = true;
		return;
	#endif
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Push ( Command )
	
	if ( CheckFilling () ) then
		send ();
		Close ();
	endif; 
	
EndProcedure

&AtClient
Procedure send ()
	
	#if ( not WebClient ) then
		set = getIDs ();
		if ( set = undefined ) then
			return;
		endif; 
		notification = new DeliverableNotification ();
		notification.Title = Output.PushNotificationTitle ( new Structure ( "User", User ) );
		notification.Text = Text;
		for each id in set do
			notification.Recipients.Add ( id );
		enddo; 
		data = new Map ();
		data [ DeliverableNotificationSubscriberType.GCM ] = GoogleProjectID;
		DeliverableNotificationSend.Send ( notification, data );
	#endif
	
EndProcedure

&AtServer
Function getIDs ()
	
	list = new Array ();
	for each receiver in getSubscribers () do
		id = receiver.Get ();
		if ( id <> undefined ) then
			list.Add ( id );
		endif; 
	enddo;
	return ? ( list.Count () = 0, undefined, list );
	
EndFunction

&AtServer
Function getSubscribers ()
	
	SetPrivilegedMode ( true );
	s = "
	|select Apps.Subscriber as Subscriber
	|from Catalog.MobileApps as Apps
	|where Apps.User in ( &Users )
	|and not Apps.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Users", Receivers.UnloadValues () );
	return q.Execute ().Unload ().UnloadColumn ( "Subscriber" );

EndFunction 

// *****************************************
// *********** Variables Initialization

#if ( Client ) then
	
GoogleProjectID = "AIzaSyAlEtCjTrPI-MsUuzvq81u1jKnkV3PxnBw"; //"21203884654";

#endif
