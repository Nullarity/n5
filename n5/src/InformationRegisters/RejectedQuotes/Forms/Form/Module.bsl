// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	applyParams ();
	setRejectionDate ();
	if ( causeAlreadyExist () ) then
		Cancel = true;
		Output.RejectionCauseAlreadyExist ();
	endif; 
	
EndProcedure

&AtServer
Procedure applyParams ()
	
	Parameters.Property ( "Quote", Record.Quote );

EndProcedure 

&AtServer
Procedure setRejectionDate ()
	
	Record.RejectDate = CurrentDate ();
	
EndProcedure 

&AtServer
Function causeAlreadyExist ()
	
	s = "
	|select top 1 RejectedQuotes.Cause
	|from InformationRegister.RejectedQuotes as RejectedQuotes
	|where RejectedQuotes.Quote = &Quote
	|";
	q = new Query ( s );
	q.SetParameter ( "Quote", Record.Quote );
	return not q.Execute ().IsEmpty ();
	
EndFunction 

&AtClient
Procedure AfterWrite ( WriteParameters )
	
	Notify ( Enum.MessageQuoteCanceled (), Record.Quote );
	
EndProcedure
