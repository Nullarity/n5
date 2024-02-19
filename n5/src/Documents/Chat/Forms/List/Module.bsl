// *****************************************
// *********** Group Form

&AtClient
Procedure AssistantFilterOnChange( Item )
	
	filterByAssistant ();
	
EndProcedure

&AtClient
Procedure filterByAssistant ()
	
	DC.ChangeFilter ( List, "Assistant", AssistantFilter, not AssistantFilter.IsEmpty () );
	
EndProcedure
