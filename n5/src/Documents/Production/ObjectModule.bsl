#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Reposted;
var Realtime;

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )

	if ( not checkServices () ) then
		Cancel = true;
		return;
	endif; 

EndProcedure

Function checkServices ()
	
	error = false;
	msg = new Structure ( "Field", Metadata ().TabularSections.Services.Attributes.Account.Presentation () );
	for each row in Services do
		if ( row.Distribution.IsEmpty ()
			and row.Account.IsEmpty () ) then
			Output.FieldIsEmpty ( msg, Output.Row ( "Services", row.LineNumber, "Account" ), Ref );
			error = true;
		endif; 
	enddo; 
	return not error;
	
EndFunction 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( not IsNew () ) then
		Catalogs.Lots.Sync ( Ref, DeletionMark );
	endif; 
	setProperties ();
	
EndProcedure

Procedure setProperties ()
	
	Reposted = Posted;
	Realtime = Forms.RealtimePosting ( ThisObject );
	
EndProcedure 

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		SequenceCost.Rollback ( Ref, Company, PointInTime () );
	endif;
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Env.Reposted = Reposted;
	Env.Realtime = Realtime;
	Cancel = not Documents.Production.Post ( Env );
	
EndProcedure

Procedure UndoPosting ( Cancel )
	
	if ( Dependencies.Exist ( Ref ) ) then
		Cancel = true;
		return;
	endif; 
	Dependencies.Unbind ( Ref );
	SequenceCost.Rollback ( Ref, Company, PointInTime () );
	
EndProcedure

#endif