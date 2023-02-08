Procedure Unbind ( Ref ) export
	
	q = new Query ( SqlDependants () );
	q.SetParameter ( "Ref", Ref );
	Clear ( Ref, q.Execute ().Unload () );
	
EndProcedure

Function SqlDependants () export
	
	s = "
	|// ^Dependants
	|select distinct Cost.Recorder as Document
	|from AccumulationRegister.Cost as Cost
	|where Cost.Dependency = &Ref
	|";
	return s;
	
EndFunction

Procedure Clear ( Ref, Table ) export
	
	for each row in Table do
		recordset = AccumulationRegisters.Cost.CreateRecordSet ();
		recordset.Filter.Recorder.Set ( row.Document );
		recordset.Read ();
		count = recordset.Count () - 1;
		while ( count >= 0 ) do
			movement = recordset [ count ];
			if ( movement.Dependency = Ref ) then
				recordset.Delete ( count );
			endif;
			count = count - 1;
		enddo; 
		recordset.Write ();
	enddo;
	
EndProcedure

Function Exist ( Ref ) export
	
	q = new Query ( SqlDependencies () );
	q.SetParameter ( "Ref", Ref );
	table = q.Execute ().Unload ();
	Show ( Table );
	return table.Count () > 0;
	
EndFunction

Procedure Show ( Table ) export
	
	for each row in Table do
		Output.UnpostLinkedDocuments ( new Structure ( "Dependency", row.Dependency ), , row.Dependency );
	enddo;
	
EndProcedure

Function SqlDependencies () export
	
	s = "
	|// ^Dependencies
	|select Cost.Dependency as Dependency
	|from AccumulationRegister.Cost as Cost
	|where Cost.Recorder = &Ref
	|and Cost.Dependency <> undefined
	|union
	|select Expenses.Source
	|from InformationRegister.ItemExpenses as Expenses
	|where Expenses.Document = &Ref
	|and Expenses.Recorder <> &Ref
	|";
	return s;
	
EndFunction
