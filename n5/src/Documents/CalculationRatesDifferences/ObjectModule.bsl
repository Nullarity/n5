#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.CalculationRatesDifferences.Post ( env );
	
EndProcedure

#endif