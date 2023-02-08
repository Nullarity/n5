
Procedure PreventIndeterminacyBeforeExecute ( Source, Cancel ) export
	
	if ( Source.DeletionMark ) then
		Cancel = true;
		preventUndefinedBehaviour ()
	endif;
	
EndProcedure

Procedure preventUndefinedBehaviour ()
	
	raise Output.DeletedTaskExecution ();
	
EndProcedure
