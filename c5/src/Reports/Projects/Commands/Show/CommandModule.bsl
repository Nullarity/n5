
&AtClient
Procedure CommandProcessing ( References, CommandExecuteParameters )
	
	openReport ( References, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( References, CommandExecuteParameters )
	
	p = ReportsSystem.GetParams ( "Projects" );
	filters = new Array ();
	filters.Add ( filterByReference ( References ) );
	type = TypeOf ( References [ 0 ] );
	if ( type = Type ( "CatalogRef.Projects" ) ) then
		filter = DC.CreateFilter ( "Project.Completed", false, , false );
		filters.Add ( filter );
	endif; 
	p.Filters = filters;
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 

&AtClient
Function filterByReference ( References )
	
	reference = References [ 0 ];
	type = TypeOf ( reference );
	if ( type = Type ( "CatalogRef.Projects" ) ) then
		filter = DC.CreateFilter ( "Project" );
	elsif ( type = Type ( "CatalogRef.Organizations" ) ) then
		filter = DC.CreateFilter ( "Customer" );
	elsif ( type = Type ( "CatalogRef.Employees" ) ) then
		filter = DC.CreateFilter ( "Employee" );
	elsif ( type = Type ( "CatalogRef.Tasks" ) ) then
		filter = DC.CreateFilter ( "Task" );
	endif; 
	if ( References.Count () > 1 ) then
		filter.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
		filter.RightValue = new ValueList ();
		filter.RightValue.LoadValues ( References );
	else
		if ( isFolder ( reference ) ) then
			filter.ComparisonType = DataCompositionComparisonType.InHierarchy;
		else
			filter.ComparisonType = DataCompositionComparisonType.Equal;
		endif; 
		filter.RightValue = reference;
	endif; 
	return filter;
	
EndFunction 

&AtServer
Function isFolder ( val Parameter )
	
	if ( Parameter.Metadata ().Hierarchical ) then
		return DF.Pick ( Parameter, "IsFolder" );
	else
		return false;
	endif; 
	
EndFunction 