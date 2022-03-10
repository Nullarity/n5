
&AtClient
Procedure CommandProcessing ( Item, ExecuteParameters )

	p = new Structure ( "Customer", Item );
	OpenForm ( "DocumentJournal.Restrictions.ListForm", new Structure ( "Filter", p ),
		ExecuteParameters.Source, ExecuteParameters.Uniqueness, ExecuteParameters.Window, ExecuteParameters.URL );

EndProcedure
