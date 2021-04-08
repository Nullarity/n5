#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( DeletionMark ) then
		PettyCash.Delete ( ThisObject );
	endif; 
	
EndProcedure

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not DeletionMark ) then
		PettyCash.Sync ( ThisObject );
	endif; 
	
EndProcedure

Procedure Posting ( Cancel, PostingMode )
	
	env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.Entry.Post ( env );
	
EndProcedure

Procedure OnSetNewNumber ( StandardProcessing, Prefix )
	
	StandardProcessing = false;
	numerator = getNumerator ();
	Prefix = Application.Prefix () + DF.Pick ( Company, "Prefix" ) + numerator.Prefix;
	numberLen = Metadata.Documents.Entry.NumberLength;
	Number = Prefix + Right ( numerator.Code, numberLen - StrLen ( Prefix ) );
	
EndProcedure

Function getNumerator () 
	
	numerator = DF.Pick ( Operation, "Numerator" );
	if ( numerator.IsEmpty () ) then
		prefix = "";
		numerator = Catalogs.Numeration.Default;
	else
		prefix = DF.Pick ( numerator, "Description" );
	endif;
	code = getCode ( numerator );
	return new Structure ( "Prefix, Code", prefix, code );
	
EndFunction

Function getCode ( Numerator ) 
	
	obj = Catalogs.Numeration.CreateItem ();
	obj.SetNewCode ( "" + Numerator );
	code = obj.Code;
	obj = Numerator.GetObject ();
	obj.Code = code;
	obj.Write ();
	return code;
	
EndFunction

#endif