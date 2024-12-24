Procedure Open ( Callback, Parameter = undefined, Form ) export
	
	OpenForm ( "CommonForm.Wait",
		new Structure ( "Callback, CallbackParameter", Callback, Parameter ), Form );
	
EndProcedure

Procedure Close () export

	Notify ( Enum.MessageCloseWaitWindow () );	
	
EndProcedure