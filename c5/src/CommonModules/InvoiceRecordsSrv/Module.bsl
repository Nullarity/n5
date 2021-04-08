Function Search ( val Ref ) export
	
	s = "
	|select top 1 Records.Ref as Ref
	|from Document.InvoiceRecord as Records
	|where Records.Base = &Ref
	|order by Records.Date desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	SetPrivilegedMode ( true );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction
