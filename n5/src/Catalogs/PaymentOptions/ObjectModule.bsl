#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkSchedule () ) then
		Cancel = true;
	endif; 
	
EndProcedure

Function checkSchedule ()
	
	doubles = CollectionsSrv.GetDuplicates ( Discounts, "Edge" );
	if ( doubles = undefined ) then
		return true;
	endif;
	p = new Structure ( "Table, Values", Metadata ().TabularSections.Discounts.Presentation () );
	for each row in doubles do
		p.Values = row.Edge;
		Output.TableDoubleRows ( p, "Discounts" );
	enddo; 
	return false;

EndFunction 

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not IsNew () ) then
		if ( DeletionMark <> DF.Pick ( Ref, "DeletionMark" ) ) then
			markKeys ( DeletionMark );
		endif;
	endif;
	
EndProcedure

Procedure markKeys ( Flag )
	
	refs = getKeys ( Flag );
	for each item in refs do
		item.GetObject ().SetDeletionMark ( Flag );
	enddo;
	
EndProcedure

Function getKeys ( Flag )
	
	s = "
	|select Keys.Ref
	|from Catalog.PaymentKeys as Keys
	|where Keys.DeletionMark = &Flag
	|and Keys.Option = &Option
	|";
	q = new Query ( s );
	q.SetParameter ( "Flag", not Flag );
	q.SetParameter ( "Option", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction

#endif