&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )

	if ( taskExists ( Source ) ) then
		showList ( Source );
	else
		newTask ( Source );
	endif;
	
EndProcedure

&AtServer
Function taskExists ( val Source )
	
	s = "
	|select allowed top 1 1
	|from Task.UserTask as Tasks
	|where not Tasks.DeletionMark
	|and not Tasks.Executed
	|and Tasks.Source = &Source
	|and Tasks.Performer = &Me
	|";
	q = new Query ( s );
	q.SetParameter ( "Source", Source );
	q.SetParameter ( "Me", SessionParameters.User );
	return not q.Execute ().IsEmpty ();
	
EndFunction

&AtClient
Procedure newTask ( Source )
	
	values = new Structure ( "Source", Source );
	OpenForm ( "Task.UserTask.ObjectForm", new Structure ( "FillingValues", values ) );
	
EndProcedure

&AtClient
Procedure showList ( Source )
	
	OpenForm ( "Task.UserTask.Form.ExistedTasks", new Structure ( "Source", Source ) );
	
EndProcedure