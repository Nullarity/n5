&AtServer
Procedure SetCreator ( Form ) export
	
	object = Form.Object;
	object.Creator = SessionParameters.User;
	if ( not Form.Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	timeEntry = TypeOf ( object.Ref ) = Type ( "DocumentRef.TimeEntry" );
	if ( timeEntry and not object.Performer.IsEmpty () ) then
		TimesheetForm.SetEmployee ( object );
		TimesheetForm.SetIndividual ( object );
	else
		if ( not object.Employee.IsEmpty () ) then
			TimesheetForm.SetIndividual ( object );
		elsif ( not object.Individual.IsEmpty () ) then
			object.Employee = findEmployee ( object );
		else
			object.Employee = DF.Pick ( object.Creator, "Employee" );
			TimesheetForm.SetIndividual ( object );
		endif;
		if ( timeEntry ) then
			object.Performer = TimesheetForm.FindPerformer ( object.Employee );
		endif;
	endif;
	
EndProcedure 

&AtServer
Procedure SetEmployee ( Object ) export
	
	performer = Object.Performer;
	employee = DF.Pick ( performer, "Employee" );
	Object.Employee = employee;
	if ( not performer.IsEmpty ()
		and employee.IsEmpty () ) then
		raise Output.EmployeeNotAssigned ( new Structure ( "User", performer ) );
	endif;
	
EndProcedure 

&AtServer
Procedure SetIndividual ( Object ) export
	
	Object.Individual = DF.Pick ( Object.Employee, "Individual" );
	
EndProcedure 

&AtServer
Function findEmployee ( Object )
	
	s = "
	|select top 1 List.Ref as Employee
	|from Catalog.Employees as List
	|	//
	|	// Employees
	|	//
	|	left join InformationRegister.Employees.SliceLast ( , Employee.Individual = &Individual ) as Employees
	|	on Employees.Employee = List.Ref
	|	and Employees.Hired
	|	//
	|	// Employment
	|	//
	|	left join InformationRegister.Employment as CurrentEmployment
	|	on CurrentEmployment.Employee = List.Ref
	|where List.Individual = &Individual
	|order by
	|	case when isnull ( Employees.Hired, false ) then 0 else 1 end desc,
	|	case CurrentEmployment.Employment
	|		when value ( Enum.Employment.Main ) then 0
	|		when value ( Enum.Employment.SecondJob ) then 1
	|		when value ( Enum.Employment.PartTime ) then 2
	|	end desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Individual", Object.Individual );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Employee );
	
EndFunction 

&AtServer
Function FindPerformer ( Employee ) export
	
	s = "
	|select top 1 Users.Ref as Performer
	|from Catalog.Users as Users
	|where not Users.DeletionMark
	|and Users.Employee = &Employee
	|";
	q = new Query ( s );
	q.SetParameter ( "Employee", Employee );
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		raise Output.UserNotFound ( new Structure ( "Employee", Employee ) );
	else
		return table [ 0 ].Performer;
	endif;
	
EndFunction


Function TotalByColumn ( Table, Column ) export
	
	total = 0;
	evening = PredefinedValue ( "Enum.Time.Evening" );
	night = PredefinedValue ( "Enum.Time.Night" );
	for each row in Table do
		type = row.TimeType;
		if ( type = night
			or type = evening ) then
			continue;
		endif; 
		total = total + row [ Column ];
	enddo; 
	return total;
	
EndFunction 

Function GetTotal ( Table ) export
	
	evening = PredefinedValue ( "Enum.Time.Evening" );
	night = PredefinedValue ( "Enum.Time.Night" );
	banked = PredefinedValue ( "Enum.Time.Banked" );
	bankedUse = PredefinedValue ( "Enum.Time.BankedUse" );
	bankedTime = 0;
	totalTime = 0;
	for each row in Table do
		type = row.TimeType;
		if ( type = evening
			or type = night ) then
			continue;
		endif; 
		time = row.TotalMinutes;
		if ( type = banked ) then
			if ( time < 0 ) then
				continue;
			endif;
			bankedTime = bankedTime - time;
		elsif ( type = bankedUse ) then
			bankedTime = bankedTime + time;
			continue;
		endif; 
		totalTime = totalTime + time;
	enddo; 
	return totalTime + Max ( 0, bankedTime );
	
EndFunction 

&AtServer
Function TotalsTable () export
	
	fields = Metadata.Documents.Timesheet.TabularSections.OneWeek.Attributes;
	table = new ValueTable ();
	columns = table.Columns;
	field = fields.TimeType;
	columns.Add ( field.Name, field.Type );
	field = fields.TotalMinutes;
	columns.Add ( field.Name, field.Type );
	return table;
	
EndFunction 

Procedure CalcMinutes ( Row ) export
	
	emptyDate = Date ( 1, 1, 1 );
	timeEnd = ? ( Row.TimeEnd = emptyDate, EndOfDay ( emptyDate ), Row.TimeEnd );
	Row.Minutes = Round ( ( timeEnd - Row.TimeStart ) / 60 );
	Row.Duration = Conversion.MinutesToDuration ( Row.Minutes );
	
EndProcedure 

Procedure CalcTotalMinutes ( Object ) export
	
	Object.Minutes = TimesheetForm.TotalByColumn ( Object.Tasks, "Minutes" );
	Object.Duration = Conversion.MinutesToDuration ( Object.Minutes );
	
EndProcedure 

&AtServer
Procedure CalcBillableMinutes ( Object ) export
	
	amount = 0;
	for each row in Object.Tasks do
		if ( row.TimeType = Enums.Time.Billable ) then
			amount = amount + row.Minutes;
		endif; 
	enddo; 
	Object.BillableMinutes = amount;
	
EndProcedure 
