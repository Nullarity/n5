
&AtClient
Procedure CommandProcessing ( Employees, Params )
	
	source = Params.Source;
	form = source.FormName;
	period = undefined;
	company = undefined;
	if ( form = "Document.Payroll.Form.Form" ) then
		object = source.Object;
		company = object.Company;
		period = new StandardPeriod ( object.DateStart, object.DateEnd );
	elsif ( form = "Document.PayAdvances.Form.Form" ) then
		object = source.Object;
		company = object.Company;
		period = new StandardPeriod ( BegOfMonth ( object.Date ), object.Date );
	endif;
	openReport ( Employees, Params, period, company );
	
EndProcedure

&AtClient
Procedure openReport ( Employees, Params, Period, Company )
	
	employee = Employees [ 0 ];
	p = ReportsSystem.GetParams ( "Timesheet" );
	filters = new Array ();
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
	filters.Add ( filter );
	if ( Period <> undefined ) then
		filter = DC.CreateParameter ( "Period", Period );
		filters.Add ( filter );
	endif;
	if ( Company <> undefined ) then
		filter = DC.CreateFilter ( "Company", Company );
		filters.Add ( filter );
	endif;
	p.Filters = filters;
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