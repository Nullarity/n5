#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not AssetsForm.CheckItems ( ThisObject ) ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	env.Realtime = Realtime;
	Cancel = not RunAssetsTransfer.Post ( env );
	
EndProcedure

#endif