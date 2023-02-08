#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	checkHourlyRate ( CheckedAttributes );
	
EndProcedure

Procedure checkHourlyRate ( CheckedAttributes )
	
	if ( Method = Enums.Calculations.MonthlyRate ) then
		CheckedAttributes.Add ( "HourlyRate" );
	endif; 
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	saveTaxes ();
	
EndProcedure

Procedure saveTaxes ()
	
	table = undefined;
	if ( not AdditionalProperties.Property ( "Taxes", table ) ) then
		return;
	endif; 
	for each row in table do
		if ( row.Dirty ) then
			changeTax ( row );
		endif; 
	enddo; 
	
EndProcedure 

Procedure changeTax ( Row )
	
	obj = Row.Tax.GetObject ();
	base = obj.BaseCalculationTypes;
	baseRow = base.Find ( Ref, "CalculationType" );
	if ( Row.Use ) then
		if ( baseRow = undefined ) then
			baseRow = base.Add ();
			baseRow.CalculationType = Ref;
		else
			return;
		endif; 
	else
		if ( baseRow = undefined ) then
			return;
		else
			base.Delete ( baseRow );
		endif; 
	endif; 
	obj.Write ();
	
EndProcedure 

#endif