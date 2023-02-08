&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	callbackParams = new Structure ( "TimeEntry, CommandExecuteParameters", CommandParameter, CommandExecuteParameters );
	OpenForm ( "Report.Projects.Form.TimeEntrySettings", , , , , , new NotifyDescription ( "ProjectAnalysisTimeEntrySettings", ThisObject, callbackParams ), FormWindowOpeningMode.LockWholeInterface );
	
EndProcedure

&AtClient
Procedure ProjectAnalysisTimeEntrySettings ( FilterParams, CommandParams ) export
	
	if ( FilterParams = undefined ) then
		return;
	endif; 
	data = getTimeEntryData ( CommandParams.TimeEntry, FilterParams );
	p = ReportsSystem.GetParams ( "Projects" );
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Project" );
	filterItem.RightValue = data.Project;
	p.Filters.Add ( filterItem );
	filterItem = DC.CreateFilter ( "Customer" );
	filterItem.RightValue = data.Customer;
	p.Filters.Add ( filterItem );
	if ( FilterParams.FilterByPerformer ) then
		filterItem = DC.CreateFilter ( "Employee" );
		filterItem.RightValue = data.Employee;
		p.Filters.Add ( filterItem );
	endif; 
	if ( FilterParams.FilterByTasks ) then
		filterItem = DC.CreateFilter ( "Task" );
		filterItem.ComparisonType = DataCompositionComparisonType.InList;
		filterItem.RightValue = new ValueList ();
		filterItem.RightValue.LoadValues ( data.Tasks );
		p.Filters.Add ( filterItem );
	endif; 
	p.GenerateOnOpen = true;
	p.Insert ( "ReportVariant", "#Detail" );
	OpenForm ( "Report.Common.Form", p, CommandParams.CommandExecuteParameters.Source, true, CommandParams.CommandExecuteParameters.Window );
	
EndProcedure 

&AtServer
Function getTimeEntryData ( val TimeEntry, val FilterParams )
	
	result = new Structure ( "Project, Customer" );
	fields = "TimeEntries.Project as Project, TimeEntries.Customer as Customer";
	if ( filterParams.FilterByPerformer ) then
		result.Insert ( "Employee" );
		fields = fields + ", TimeEntries.Employee as Employee";
	endif; 
	s = "
	|select " + fields + "
	|from Document.TimeEntry as TimeEntries
	|where TimeEntries.Ref = &TimeEntry
	|";
	if ( filterParams.FilterByTasks ) then
		s = s + ";
		|select distinct Tasks.Task as Task
		|from Document.TimeEntry.Tasks as Tasks
		|where Tasks.Ref = &TimeEntry
		|";
	endif; 
	q = new Query ( s );
	SetPrivilegedMode ( true );
	q.SetParameter ( "TimeEntry", TimeEntry );
	data = q.ExecuteBatch ();
	SetPrivilegedMode ( false );
	FillPropertyValues ( result, data [ 0 ].Unload () [ 0 ] );
	if ( filterParams.FilterByTasks ) then
		documentTasks = data [ 1 ].Unload ();
		result.Insert ( "Tasks", new Array () );
		for each task in documentTasks do
			result.Tasks.Add ( task.Task );
		enddo; 
	endif;
	return result;
	
EndFunction 
