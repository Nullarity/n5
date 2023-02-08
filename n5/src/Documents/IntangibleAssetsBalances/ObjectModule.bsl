#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not AssetsForm.CheckDepreciation ( ThisObject, "Items" ) ) then
		Cancel = true;
		return;
	endif;
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not RunAssetsBalances.Post ( env );
	
EndProcedure

#endif