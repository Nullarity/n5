#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;

Procedure AfterOutput () export

	Params.Result.ShowRowGroupLevel ( 1 );
	
EndProcedure

#endif
