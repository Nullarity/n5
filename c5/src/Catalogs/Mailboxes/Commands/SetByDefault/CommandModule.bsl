
&AtClient
Procedure CommandProcessing ( Box, CommandExecuteParameters )
	
	setByDefault ( Box );
	NotifyChanged ( Type ( "CatalogRef.Mailboxes" ) );
	
EndProcedure

&AtServer
Procedure setByDefault ( val Box )
	
	Mailboxes.SetByDefault ( Box );
	
EndProcedure 