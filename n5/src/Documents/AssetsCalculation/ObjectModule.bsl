#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Realtime;

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( WriteMode = DocumentWriteMode.Posting
		and not Documents.AssetsCalculation.CheckDate ( Ref, Date ) ) then
		Cancel = true;	
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
	Cancel = not Documents.AssetsCalculation.Post ( env );
	
EndProcedure

#endif