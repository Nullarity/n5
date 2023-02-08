#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "User" );
	p.Insert ( "OldTenants" );
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	Perform ( Params, JobKey );
	
EndProcedure 

Function Perform ( Params, JobKey ) export
	
	SetPrivilegedMode ( true );
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	return obj.Errors.Count () = 0;
	
EndFunction

#endif