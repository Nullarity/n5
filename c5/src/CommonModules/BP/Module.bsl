
Function MyTask ( Ref ) export
	
	text = "select top 1 null from Task.Task.TasksByExecutive where Ref = &Ref";
	q = new Query ( text );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ().Count () = 1;

EndFunction
 
Procedure Remove ( Process ) export
	
	if ( Process.IsEmpty () ) then
		return;
	endif; 
	obj = Process.GetObject ();
	if ( obj <> undefined ) then
		obj.Delete ();
	endif; 
	
EndProcedure 

Procedure RemoveTasks ( Process, Forever = true ) export
	
	activities = getTasks ( Process );
	for each task in activities do
		obj = task.GetObject ();
		if ( Forever ) then
			obj.Delete ();
		else
			obj.SetDeletionMark ( true );
		endif;
	enddo; 
	
EndProcedure 

Function getTasks ( Process )
	
	s = "
	|select Tasks.Ref as Ref
	|from Task." + Process.Metadata ().Task.Name + " as Tasks
	|where Tasks.BusinessProcess = &Process
	|and not Tasks.DeletionMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Process", Process );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction 
