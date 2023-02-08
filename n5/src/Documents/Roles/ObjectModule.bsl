#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkDepartment ( CheckedAttributes );
	
EndProcedure 

Procedure checkDepartment ( CheckedAttributes )
	
	if ( Role = Enums.Roles.DepartmentHead ) then
		CheckedAttributes.Add ( "Department" );
	endif; 
	
EndProcedure 

#endif