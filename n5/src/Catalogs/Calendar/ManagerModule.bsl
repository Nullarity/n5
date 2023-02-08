#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( "Date" );
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Format ( Data.Date, "DLF=D" );
	
EndProcedure

Function GetDate ( Date ) export
	
	SetPrivilegedMode ( true );
	if ( Date = undefined
		or Date = Date ( 1, 1, 1 ) ) then
		return EmptyRef ();
	endif;
	BeginTransaction ();
	lock ();
	looking = BegOfDay ( Date );
	result = Catalogs.Calendar.FindByAttribute ( "Date", looking );
	if ( result.IsEmpty () ) then
		obj = Catalogs.Calendar.CreateItem ();
		obj.Date = looking;
		obj.Description = Format ( looking, "DLF=D" );
		obj.Write ();
		result = obj.Ref;
		CommitTransaction ();
	endif;
	return result;
	
EndFunction

Procedure lock ()
	
	lock = new DataLock ();
	item = lock.Add ( "Catalog.Calendar");
	item.Mode = DataLockMode.Exclusive;
	lock.Lock ();
	
EndProcedure

#endif