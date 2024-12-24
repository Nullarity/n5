// *****************************************
// *********** Form events

&AtClient
Procedure OnOpen ( Cancel )
	
	AttachIdleHandler ( "callback", 0.1, true );
	
EndProcedure

&AtClient
Procedure callback () export
	
	RunCallback (
		new CallbackDescription ( Parameters.Callback, FormOwner, Parameters.CallbackParameter )
	);
	
EndProcedure

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageCloseWaitWindow () ) then
		Close ();
	endif;
	
EndProcedure
