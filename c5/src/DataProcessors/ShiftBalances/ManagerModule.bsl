#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Date" );
	p.Insert ( "Company" );
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

#endif