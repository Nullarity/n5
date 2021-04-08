
&AtClient
Procedure CommandProcessing ( Employees, Params )
	
	openReport ( Employees, Params );
	
EndProcedure

&AtClient
Procedure openReport ( Employees, Params )
	
	employee = Employees [ 0 ];
	p = ReportsSystem.GetParams ( "Timesheet" );
	p.Filters = new Array ();
	filter = DC.CreateFilter ( "Employee" );
	if ( Employees.Count () = 1 ) then
		if ( isFolder ( employee ) ) then
			filter.ComparisonType = DataCompositionComparisonType.InHierarchy;
		else
			filter.ComparisonType = DataCompositionComparisonType.Equal;
		endif; 
		filter.RightValue = employee;
	else
		filter.ComparisonType = DataCompositionComparisonType.InList;
		filter.RightValue = new ValueList ();
		filter.RightValue.LoadValues ( Employees );
	endif; 
	p.Filters.Add ( filter );
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, Params.Source, true, Params.Window );
	
EndProcedure 

&AtServer
Function isFolder ( Parameter )
	
	if ( Parameter.Metadata ().Hierarchical ) then
		return DF.Pick ( Parameter, "IsFolder" );
	else
		return false;
	endif; 
	
EndFunction 