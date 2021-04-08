
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	if ( not Commands.CheckParameter ( CommandParameter, true, true ) ) then
		return;
	endif; 
	Output.SendRegistrationDataInformation ( ThisObject, CommandParameter );
	
EndProcedure

&AtClient
Procedure SendRegistrationDataInformation ( Answer, User ) export
	
	if ( Answer = DialogReturnCode.OK ) then
		sendEmail ( User );
		Output.RegistrationDataSendedSuccessfully ();
	endif;
	
EndProcedure 

&AtServer
Procedure sendEmail ( User )
	
	p = new Array ();
	p.Add ( User );
	Jobs.Run ( "RegistrationSrv.Send", p );
	
EndProcedure
