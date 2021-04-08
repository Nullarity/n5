
&AtClient
Procedure CommandProcessing ( Source, ExecuteParameters )
	
	p = new Structure ( "Source", Source );
	OpenForm ( "Task.UserTask.Form.Embedded", p, ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );
	
EndProcedure
