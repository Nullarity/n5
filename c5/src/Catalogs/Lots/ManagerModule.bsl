#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Sync ( Document, DeletionMark ) export
	
	SetPrivilegedMode ( true );
	ref = findLot ( Document, DeletionMark );
	if ( ref = undefined ) then
		return;
	endif; 
	obj = ref.GetObject ();
	obj.SetDeletionMark ( DeletionMark );
	
EndProcedure 

Function findLot ( Document, DeletionMark )
	
	s = "
	|select top 1 Lots.Ref as Ref
	|from Catalog.Lots as Lots
	|where Lots.Document = &Document
	|and Lots.DeletionMark = &CurrentMark
	|";
	q = new Query ( s );
	q.SetParameter ( "Document", Document );
	q.SetParameter ( "CurrentMark", not DeletionMark );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

#endif