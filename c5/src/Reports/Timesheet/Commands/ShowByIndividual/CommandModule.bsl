
&AtClient
Procedure CommandProcessing ( Individual, Params )
	
	openReport ( Params.Source.Employee.Ref, Params );
	
EndProcedure

&AtClient
Procedure openReport ( Employee, Params )
	
	p = ReportsSystem.GetParams ( "Timesheet" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Employee" );
	filter.ComparisonType = DataCompositionComparisonType.Equal;
	filter.RightValue = Employee;
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, Params.Source, true, Params.Window );
	
EndProcedure 
