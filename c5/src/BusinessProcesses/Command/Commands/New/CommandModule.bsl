
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )

	if ( commandExists ( Source ) ) then
		showList ( Source );
	else
		newCommand ( Source );
	endif;
	
EndProcedure

&AtServer
Function commandExists ( val Source )
	
	s = "
	|select allowed top 1 1
	|from BusinessProcess.Command as Commands
	|where not Commands.DeletionMark
	|and not Commands.Completed
	|and Commands.Source = &Source
	|and Commands.Creator = &Me
	|";
	q = new Query ( s );
	q.SetParameter ( "Source", Source );
	q.SetParameter ( "Me", SessionParameters.User );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtClient
Procedure newCommand ( Source )
	
	values = new Structure ( "Source", Source );
	OpenForm ( "BusinessProcess.Command.ObjectForm", new Structure ( "FillingValues", values ) );
	
EndProcedure

&AtClient
Procedure showList ( Source )
	
	OpenForm ( "BusinessProcess.Command.Form.ExistedCommands", new Structure ( "Source", Source ) );
	
EndProcedure
