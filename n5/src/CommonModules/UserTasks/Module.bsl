&AtServer
Procedure InitList ( List ) export
	
	DC.SetParameter ( List, "Performer", SessionParameters.User );
	
EndProcedure

&AtClient
Procedure Click ( Item, SelectedRow, Field, StandardProcessing ) export
	
	if ( Field.Name = "TaskRef" ) then
		task = Item.CurrentData.TaskRef;
		if ( not task.IsEmpty () ) then
			StandardProcessing = false;
			OpenForm ( "Task.UserTask.ObjectForm", new Structure ( "Key", task ) );
		endif;
	endif;
	
EndProcedure

&AtClient
Procedure ApplyAction ( Source, Action ) export

	if ( TypeOf ( Source ) = Type ( "TaskRef.UserTask" ) ) then
		PerformerTasksSrv.ApplyAction ( Source, Action );
	else
		object = Source.Object;
		object.Action = Action;
		params = new Structure ( "ВыполнитьЗадачу", true );
		Source.Write ( params );
		Source.Close ();
	endif;

EndProcedure