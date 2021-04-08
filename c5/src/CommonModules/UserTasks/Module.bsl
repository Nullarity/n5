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
