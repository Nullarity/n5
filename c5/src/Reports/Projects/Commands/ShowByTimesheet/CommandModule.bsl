
&AtClient
Procedure CommandProcessing ( CommandParameter, CommandExecuteParameters )
	
	openReport ( CommandParameter, CommandExecuteParameters );
	
EndProcedure

&AtClient
Procedure openReport ( Timesheet, CommandExecuteParameters )
	
	data = getTimesheetData ( Timesheet );
	p = ReportsSystem.GetParams ( "Projects" );
	p.Filters = new Array ();
	filterItem = DC.CreateFilter ( "Employee" );
	filterItem.RightValue = data.Employee;
	p.Filters.Add ( filterItem );
	filterItem = DC.CreateFilter ( "Project" );
	filterItem.ComparisonType = DataCompositionComparisonType.InList;
	filterItem.RightValue = new ValueList ();
	filterItem.RightValue.LoadValues ( data.Projects );
	p.Filters.Add ( filterItem );
	p.GenerateOnOpen = true;
	p.Insert ( "ReportVariant", "#Detail" );
	OpenForm ( "Report.Common.Form", p, CommandExecuteParameters.Source, true, CommandExecuteParameters.Window );
	
EndProcedure 

&AtServer
Function getTimesheetData ( val Timesheet )
	
	result = new Structure ( "Employee, Projects" );
	data = DF.Values ( Timesheet, "Employee, TableName" );
	s = "
	|select allowed distinct Time.Project as Project
	|from Document.Timesheet." + data.TableName + " as Time
	|where Time.Ref = &Timesheet
	|";
	q = new Query ( s );
	q.SetParameter ( "Timesheet", Timesheet );
	result.Projects = q.Execute ().Unload ().UnloadColumn ( "Project" );
	result.Employee = data.Employee;
	return result;
	
EndFunction 
