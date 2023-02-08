Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	//@skip-warning
	obj.Exec ();
	
EndProcedure 

Function Check () export
	
	//@skip-warning
	return Create ().Check ();
	
EndFunction

Function Reset () export
	
	//@skip-warning
	return Create ().Reset ();
	
EndFunction
