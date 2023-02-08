// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( MailChecking.ProfileExists () ) then
		setInitialStatus ();
		if ( not MailChecking.AlreadyStarted () ) then
			MailChecking.Start ();
		endif; 
	else
		NoProfile = true;
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|NoProfile show NoProfile;
	|Checking show Checking;
	|Success show Success;
	|Error show ErrorCode <> 0;
	|Outgoing show ErrorCode = 2
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure setInitialStatus ()
	
	Information = Output.Connecting ();
	Checking = true;
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	AttachIdleHandler ( "check", 1 );
	
EndProcedure

&AtClient
Procedure check () export
	
	status = MailChecking.GetStatus ();
	Information = status.Message;
	complete = status.Complete;
	ErrorCode = status.ErrorCode;
	Outgoing = status.OutgoingEmail;
	Success = complete and ( ErrorCode = 0 );
	Checking = not complete;
	if ( complete ) then
		DetachIdleHandler ( "check" );
		applyNewStatus ();
		if ( status.Count > 0 ) then
			Notify ( Enum.MessageNewMail () );
		endif; 
	endif;
	
EndProcedure 

&AtServer
Procedure applyNewStatus ()
	
	MailChecking.DeleteStatus ();
	Appearance.Apply ( ThisObject );
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CreateProfile ( Command )
	
	Close ();
	OpenForm ( "Catalog.Mailboxes.ObjectForm" );
	
EndProcedure

// *****************************************
// *********** Group Error

&AtClient
Procedure OutgoingClick ( Item, StandardProcessing )
	
	Close ();
	
EndProcedure
