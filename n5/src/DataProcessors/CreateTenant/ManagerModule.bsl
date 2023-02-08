#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure ();
	p.Insert ( "User" );
	p.Insert ( "Creator" );
	p.Insert ( "Password" );
	p.Insert ( "Company" );
	p.Insert ( "Email" );
	p.Insert ( "Language" );
	p.Insert ( "PromoCode" );
	p.Insert ( "Show", true );
	p.Insert ( "Protection", false );
	p.Insert ( "OSAuth", false );
	p.Insert ( "OSUser" );
	p.Insert ( "Result" );
	return p;
	
EndFunction

Function Enroll ( Params ) export

	obj = Create ();
	obj.Parameters = Params;
	return obj.Enroll ();

EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	SetPrivilegedMode ( true );
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

#endif