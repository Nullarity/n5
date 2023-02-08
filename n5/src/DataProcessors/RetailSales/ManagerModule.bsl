#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function GetParams () export
	
	p = new Structure();
	p.Insert ( "Company" );
	p.Insert ( "Department" );
	p.Insert ( "Location" );
	p.Insert ( "Method" );
	p.Insert ( "Warehouse" );
	p.Insert ( "Day" );
	p.Insert ( "Memo" );
	p.Insert ( "Address" );
	return p;
	
EndFunction 

Procedure Exec ( Params, JobKey ) export
	
	obj = Create ();
	obj.Parameters = Params;
	obj.JobKey = JobKey;
	obj.Exec ();
	
EndProcedure 

#endif