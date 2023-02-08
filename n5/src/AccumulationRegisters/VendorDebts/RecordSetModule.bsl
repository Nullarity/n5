#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure OnWrite ( Cancel, Replacing )

	RunDebts.SyncRecords ( ThisObject );

EndProcedure

#endif