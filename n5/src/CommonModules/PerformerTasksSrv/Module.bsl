Procedure ApplyAction ( val Task, val Action ) export

	object = Task.GetObject ();
	object.Action = Action;
	object.ExecuteTask ();

EndProcedure