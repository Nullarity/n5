
// *****************************************
// *********** Group Form

&AtClient
Procedure SenderFilterOnChange ( Item )
	
	filterBySender ();
	
EndProcedure

&AtServer
Procedure filterBySender ()
	
	DC.ChangeFilter ( List, "Sender", SenderFilter, not SenderFilter.IsEmpty () );
	
EndProcedure 

&AtClient
Procedure ReceiverFilterOnChange ( Item )
	
	filterByReceiver ();
	
EndProcedure

&AtServer
Procedure filterByReceiver ()
	
	DC.ChangeFilter ( List, "Receiver", ReceiverFilter, not ReceiverFilter.IsEmpty () );
	
EndProcedure 
