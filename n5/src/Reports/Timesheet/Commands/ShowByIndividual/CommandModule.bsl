
&AtClient
Procedure CommandProcessing ( Individual, Params )
	
	source = Params.Source;
	form = source.FormName;
	period = undefined;
	company = undefined;
	if ( form = "Catalog.Individuals.Form.Form" ) then
		employee = Params.Source.Employee.Ref;
	elsif ( form = "Document.Payroll.Form.Form" ) then
		object = source.Object;
		company = object.Company;
		employee = object.Compensations.FindRows ( new Structure ( "Individual", Individual ) ) [ 0 ].Employee;
		period = new StandardPeriod ( object.DateStart, object.DateEnd );
	elsif ( form = "Document.PayEmployees.Form.Form"
		or form = "Document.PayAdvances.Form.Form" ) then
		object = source.Object;
		company = object.Company;
		date = object.Date;
		employee = findEmployee ( Individual, date );
		period = new StandardPeriod ( BegOfMonth ( date ), EndOfMonth ( date ) );
	endif;
	openReport ( employee, Params, period, company );
	
EndProcedure

&AtClient
Procedure openReport ( Employee, Params, Period = undefined, Company = undefined )
	
	p = ReportsSystem.GetParams ( "Timesheet" );
	filters = new Array ();
	item = DC.CreateFilter ( "Employee" );
	item.ComparisonType = DataCompositionComparisonType.Equal;
	item.RightValue = Employee;
	filters.Add ( item );
	if ( Period <> undefined ) then
		item = DC.CreateParameter ( "Period", Period );
		filters.Add ( item );
	endif;
	if ( Company <> undefined ) then
		item = DC.CreateFilter ( "Company", Company );
		filters.Add ( item );
	endif;
	p.Filters = filters;
	p.GenerateOnOpen = true;
	OpenForm ( "Report.Common.Form", p, Params.Source, true, Params.Window );
	
EndProcedure 

&AtServer
Function findEmployee ( val Individual, val Date )
	
	s = "
	|select top 1 Employees.Employee as Employee
	|from InformationRegister.Employees.SliceLast ( &Date, Employee in (
	|	select List.Ref as Ref
	|	from Catalog.Employees as List
	|	where not List.DeletionMark
	|	and List.Individual = &Individual
	|) ) Employees
	|order by case when Employees.Hired then 0 else 1 end";
	q = new Query ( s );
	q.SetParameter ( "Individual", Individual );
	q.SetParameter ( "Date", Date );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Employee );

EndFunction
