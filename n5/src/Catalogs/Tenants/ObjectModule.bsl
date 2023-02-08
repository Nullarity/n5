#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var NewTenant;

Procedure BeforeWrite ( Cancel )
	
	NewTenant = IsNew ();
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( NewTenant ) then
		enrollExchange ();
	endif; 
		
EndProcedure

Procedure enrollExchange ()
	
	r = InformationRegisters.ExchangeHistory.CreateRecordManager ();
	r.Tenant = Ref;
	r.Date = CurrentSessionDate ();
	r.Write ();
	
EndProcedure 

#endif