#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	PettyCash.Sync ( ThisObject );
	
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
	
	transaction = not TransactionActive ();
	if ( transaction ) then
		BeginTransaction ();
	endif;
	numerator = DF.Pick ( Operation, "Numerator" );
	lockNumerator ( numerator );
	if ( numerator.IsEmpty () ) then
		prefix = "";
		numerator = Catalogs.Numeration.Default;
	else
		prefix = DF.Pick ( numerator, "Description" );
	endif;
	code = getCode ( numerator );
	if ( transaction ) then
		CommitTransaction ();
	endif;
	return new Structure ( "Prefix, Code", prefix, code );

EndFunction

Procedure lockNumerator ( Numerator )
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.Numeration" );
	item.SetValue ( "Ref", Numerator );
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure

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