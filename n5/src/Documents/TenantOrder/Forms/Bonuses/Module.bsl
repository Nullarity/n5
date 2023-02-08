// *****************************************
// *********** Group Form

&AtClient
Procedure AgentFilterOnChange ( Item )
	
	filterByAgent ();
	
EndProcedure

&AtServer
Procedure filterByAgent ()
	
	DC.ChangeFilter ( List, "Agent", AgentFilter, not AgentFilter.IsEmpty () );
	
EndProcedure 