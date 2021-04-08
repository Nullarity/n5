#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not IsFolder and not Service ) then
		CheckedAttributes.Add ( "CostMethod" );
	endif; 
	
EndProcedure

Procedure BeforeWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	if ( not IsNew () ) then
		if ( DeletionMark <> DF.Pick ( Ref, "DeletionMark" ) ) then
			markKeys ( DeletionMark );
		endif;
	endif;
	defaultName ();
	
EndProcedure

Procedure defaultName ()
	
	if ( Description = "" ) then
		Description = Output.WorkingDescription ();
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
	|from Catalog.ItemKeys as Keys
	|where Keys.DeletionMark = &Flag
	|and Keys.Item = &Item
	|";
	q = new Query ( s );
	q.SetParameter ( "Flag", not Flag );
	q.SetParameter ( "Item", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Ref" );
	
EndFunction

#endif