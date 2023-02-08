
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openReport ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( CommandParameter, CommandExecuteParameters )
	
	parameter = CommandParameter [ 0 ];
	typeOfParameter = TypeOf ( parameter );
	p = ReportsSystem.GetParams ( "WorkLog" );
	p.Filters = new Array ();
	checkFolder = true;
	if ( typeOfParameter = Type ( "DocumentRef.Timesheet" ) ) then
		filterItem = DC.CreateFilter ( "Timesheet" );
		checkFolder = false;
	elsif ( typeOfParameter = Type ( "CatalogRef.Projects" ) ) then
		filterItem = DC.CreateFilter ( "Project" );
	elsif ( typeOfParameter = Type ( "CatalogRef.Organizations" ) ) then
		filterItem = DC.CreateFilter ( "Customer" );
	elsif ( typeOfParameter = Type ( "CatalogRef.Employees" ) ) then
		filterItem = DC.CreateFilter ( "Employee" );
	elsif ( typeOfParameter = Type ( "CatalogRef.Tasks" ) ) then
		filterItem = DC.CreateFilter ( "Task" );
	endif; 
	if ( CommandParameter.Count () > 1 ) then
		filterItem.ComparisonType = DataCompositionComparisonType.InList;
		filterItem.RightValue = new ValueList ();
		filterItem.RightValue.LoadValues ( CommandParameter );
	else
		if ( checkFolder and isFolder ( parameter ) ) then
			filterItem.ComparisonType = DataCompositionComparisonType.InHierarchy;
		else
			filterItem.ComparisonType = DataCompositionComparisonType.Equal;
		endif; 
		filterItem.RightValue = parameter;
	endif; 
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 

&AtServer
Function isFolder ( Parameter )
	
	if ( Parameter.Metadata ().Hierarchical ) then
		return DF.Pick ( Parameter, "IsFolder" );
	else
		return false;
	endif; 
	
EndFunction 