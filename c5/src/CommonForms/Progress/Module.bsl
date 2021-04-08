&AtClient
var Completed;
&AtClient
var Messages;
&AtClient
var ClosingStarted;

// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	initStatus ();
	
EndProcedure

&AtServer
Procedure initStatus ()
	
	Status = Output.Processing ();
	
EndProcedure 

&AtClient
Procedure OnOpen ( Cancel )
	
	init ();
	if ( Parameters.ShowStatus ) then
		AttachIdleHandler ( "checkStatus", 1 );
	else
		AttachIdleHandler ( "checkFinish", 1 );
	endif;
	
EndProcedure

&AtClient
Procedure init ()

	Completed = false;
	ClosingStarted = false;

EndProcedure

&AtClient
Procedure checkStatus () export
	
	currentStatus = "";
	error = false;
	active = getStatus ( Parameters.JobKey, currentStatus, error, Messages );
	if ( active ) then
		if ( currentStatus <> "" and currentStatus <> Status ) then
			Status = currentStatus;
		endif; 
	else
		DetachIdleHandler ( "checkStatus" );
		if ( error ) then
			Status = currentStatus;
		endif;
		showMessages ( error );
	endif; 
	
EndProcedure 

&AtServerNoContext
Function getStatus ( val JobKey, Status, Error, Messages )
	
	data = InformationRegisters.Jobs.Get ( new Structure ( "JobKey", JobKey ) );
	Status = data.Status;
	Error = data.Error;
	return jobIsActive ( JobKey, Messages );
	
EndFunction

&AtServerNoContext
Function jobIsActive ( val JobKey, Messages )
	
	job = Jobs.GetBackground ( JobKey, false );
	if ( job = undefined ) then
		return false;
	elsif ( job.State = BackgroundJobState.Active ) then
		return true;
	else
		scope = job.GetUserMessages ();
		if ( scope.Count () > 0 ) then
			Messages = scope;
		endif; 
		return false;
	endif;
	
EndFunction

&AtClient
Procedure showMessages ( Error )
	
	if ( Error ) then
		Title = Output.ErrorTitle ();
	elsif ( Messages = undefined ) then
		Completed = true;
		closeProgress ();
		return;
	else
		Title = Output.InfoDetected ();
	endif;
	outputMessages ();
	if ( Error ) then
		MessagesList.Add ( Status );
	elsif ( MessagesList.Count () = 0 ) then
		closeProgress ();
		return;
	endif;
	Items.CloseMessages.DefaultButton = true;
	Items.Progress.Visible = false;
	Items.Messages.Visible = true;
	
EndProcedure 

&AtClient
Procedure closeProgress ()
	
	ClosingStarted = true;
	Close ( Completed );
	
EndProcedure 

&AtClient
Procedure outputMessages ()
	
	if ( Messages = undefined ) then
		return;
	endif;
	target = Parameters.MessageReceiver;
	if ( target = undefined
		or Parameters.HighlightMessages ) then
		for each msg in Messages do
			MessagesList.Add ( , msg.Text );
		enddo;
	else
		for each msg in Messages do
			msg.TargetID = target; 
			msg.Message ();
		enddo;
	endif;

EndProcedure

&AtClient
Procedure checkFinish () export
	
	if ( jobIsActive ( Parameters.JobKey, Messages ) ) then
		return;
	endif; 
	DetachIdleHandler ( "checkFinish" );
	showMessages ( false );
	
EndProcedure 

&AtClient
Procedure BeforeClose ( Cancel, Exit, MessageText, StandardProcessing )
	
	if ( ClosingStarted ) then
		return;
	endif; 
	Cancel = true;
	ClosingStarted = true;
	AttachIdleHandler ( "startClosing", 0.1, true );
	
EndProcedure

&AtClient
Procedure startClosing ()
	
	// Bug workaround to prevent 8.3.14 failing into infinite loop
	Close ( Completed );
	
EndProcedure
