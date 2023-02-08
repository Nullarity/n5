#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Run ( ID ) export
	
	DataProcessors.UpdateConfiguration.Create ().Update ( ID );
	
EndProcedure 

#endif