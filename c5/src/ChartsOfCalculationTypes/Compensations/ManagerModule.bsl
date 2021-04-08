Function Default ( Method ) export
	
	s = "
	|select top 1 Compensations.Ref as Ref
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where not Compensations.DeletionMark
	|and Compensations.Method = &Method
	|";
	q = new Query ( s );
	q.SetParameter ( "Method", Method );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction