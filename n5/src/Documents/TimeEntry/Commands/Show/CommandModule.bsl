
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openList ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openList ( CommandParameter, CommandExecuteParameters )
	
	p = new Structure ( "Filter", new Structure () );
	if ( TypeOf ( CommandParameter ) = Type ( "CatalogRef.Projects" ) ) then
		p.Filter.Insert ( "Project", CommandParameter );
	elsif ( TypeOf ( CommandParameter ) = Type ( "CatalogRef.Organizations" ) ) then
		p.Filter.Insert ( "Customer", CommandParameter );
	elsif ( TypeOf ( CommandParameter ) = Type ( "CatalogRef.Employees" ) ) then
		p.Filter.Insert ( "Employee", CommandParameter );
	endif; 
	OpenForm ( "Document.TimeEntry.ListForm", p, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL );
	
EndProcedure 
