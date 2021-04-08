#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not Periods.Ok ( Date, DateTo ) ) then
		Output.PricesPeriodError ( , "Date" );
		Cancel = true;
		return;
	endif; 
	if ( Simple ) then
		if ( not checkPrices () ) then
			Cancel = true;
			return;
		endif;
	endif; 
	
EndProcedure

Function checkPrices ()
	
	if ( Items [ 0 ].Prices.IsEmpty () ) then
		p = new Structure ( "Field", Metadata ().TabularSections.Items.Attributes.Prices.Presentation () );
		Output.FieldIsEmpty ( p, , Ref );
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.SetupPrices.Post ( env );
	
EndProcedure

#endif