Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	obj.Exec ();
	
EndProcedure 

Function Check () export
	
	return Create ().Check ();
	
EndFunction

Function Reset () export
	
	return Create ().Reset ();
	
EndFunction
