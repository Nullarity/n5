#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#if ( Server ) then
	
Function Events () export
	
	p = Reporter.Events ();
	p.OnCheck = true;
	p.AfterOutput = true;
	p.OnGetColumns = true;
	return p;
	
EndFunction 

Procedure OnGetColumns ( Variant, Columns ) export
	
	if ( Variant = "#Mobile" ) then
		Columns = new Array ();
		Columns.Add ( Reporter.ColumnStruct ( "Customer", 9 ) );
		Columns.Add ( Reporter.ColumnStruct ( "Employee", 10 ) );
	elsif ( Variant = "#MobileByDays" ) then
		Columns = new Array ();
		Columns.Add ( Reporter.ColumnStruct ( "Day", 15 ) );
	endif; 
	
EndProcedure 

#endif

#endif