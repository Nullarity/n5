#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "Result" );
	p.Insert ( "Files" );
	p.Insert ( "Assistant" );
	p.Insert ( "Session" );
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

Function Descriptor ( Name, Size, Data ) export

	return new Structure ( "Name, Size, Data", Name, Size, Data );

EndFunction

#endif