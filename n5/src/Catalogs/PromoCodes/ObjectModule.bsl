#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkAgent ( CheckedAttributes );
	checkBonus ( CheckedAttributes );
	
EndProcedure

Procedure checkAgent ( CheckedAttributes )
	
	if ( Bonus > 0 ) then
		CheckedAttributes.Add ( "Agent" );
	endif; 
	
EndProcedure 

Procedure checkBonus ( CheckedAttributes )
	
	if ( not Agent.IsEmpty () ) then
		CheckedAttributes.Add ( "Bonus" );
	endif; 
	
EndProcedure 

#endif