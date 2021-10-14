// Test holiday for specific territorial devision
// - Hire two employees to Division1 and Division2
// - Create Payroll & check their scheduled time

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0DS" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region createPayroll
Call("Documents.Payroll.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando ( "e1cib/command/Document.Payroll.Create" );
	Put ("#Company", this.Company);
	Click("#Button0", "1?:*"); // Yes
	Set ( "#Date", Format (EndOfMonth(this.Date), "DLF=D") );
	Set("#Memo", id);
	Click("#JustSave");
endif;

Click ( "#Fill" );
With ();
Click ( "#FormFill" );
Pause(3 * __.Performance);
With();
Activate("#Compensations");
#endregion

#region checkHolidays
daysEmployee1 = Number ( Fetch("#Compensations / #CompensationsDays [1]") );
daysEmployee2 = Number ( Fetch("#Compensations / #CompensationsDays [2]") );
difference = daysEmployee1 - daysEmployee2;
Assert ( difference, "Second employee should work 1 day less because of local holiday" ).Equal(1);
#endregion

#region checkCalculations
Check("#Compensations / #CompensationsResult [1]", 10000);
Check("#Compensations / #CompensationsResult [2]", 10000);
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", BegOfMonth (CurrentDate()) );
	this.Insert ( "Company", "Company " + id );
	this.Insert ( "Division", "Division " + id );
	this.Insert ( "HolidaysCalendar", "Holidays " + id );
	this.Insert ( "Schedule", "Schedule " + id );
	this.Insert ( "Department1", "Department1 " + id );
	this.Insert ( "Department2", "Department2 " + id );
	this.Insert ( "Employees", getEmployees () );
	this.Insert ( "MonthlyRate", "Monthly " + id );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;

	#region newCompany
	Call ( "Catalogs.Companies.Create", this.Company );
	#endregion

	#region newDivision
	p = Call ( "Catalogs.Divisions.Create.Params" );
	p.Description = this.Division;
	p.Company = this.Company;
	Call ( "Catalogs.Divisions.Create", p );
	#endregion

	#region newDepartment1
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department1;
	p.Company = this.Company;
	Call ( "Catalogs.Departments.Create", p );
	#endregion

	#region newDepartment2
	p.Description = this.Department2;
	p.Division = this.Division;
	Call ( "Catalogs.Departments.Create", p );
	#endregion

	#region newHolidays
	days = new Array ();
	day = Call ( "Catalogs.Holidays.Create.Day" );
	day.Title = "Common Holiday " + id;
	workDay = this.Date;
	while ( true ) do
		if (WeekDay (workDay)<6) then
			break;
		endif;
		workDay = workDay + 86400;
	enddo;
	day.Day = workDay;
	days.Add (day);
	day = Call ( "Catalogs.Holidays.Create.Day" );
	day.Title = "Local Holiday " + id;
	day.Division = this.Division;
	day.Day = workDay + 7 * 86400;
	days.Add (day);
	p = Call ( "Catalogs.Holidays.Create.Params" );
	p.Description = this.HolidaysCalendar;
	p.Days = days;
	Call ( "Catalogs.Holidays.Create", p );
	#endregion
	
	#region newSchedule
	p = Call ( "Catalogs.Schedules.Create.Params" );
	p.Description = this.Schedule;
	p.Holidays = this.HolidaysCalendar;
	Call ( "Catalogs.Schedules.Create", p );
	#endregion

	#region newCompensation
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	compensation = this.MonthlyRate;
	p.Description = compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	#endregion

	#region newEmployee
	for each employee in this.Employees do
		p = Call ( "Catalogs.Employees.Create.Params" );
		p.Description = employee.Name;
		p.Company = this.Company;
		p.Deductions = "P";
		p.DeductionsDate = employee.DateStart;
		Call ( "Catalogs.Employees.Create", p );
	enddo;
	#endregion

	#region hiring
	monthlyRate = this.MonthlyRate;
	schedule = this.Schedule;
	params = Call ( "Documents.Hiring.Create.Params" );
	params.Company = this.Company;
	for each employee in this.Employees do
		p = Call ( "Documents.Hiring.Create.Row" );
		p.Employee = employee.Name;
		p.Schedule = schedule;
		p.DateStart = Format ( employee.DateStart, "DLF=D" );
		p.DateEnd = Format ( employee.DateEnd, "DLF=D" );
		p.Department = employee.Department;
		p.Position = "Manager";
		p.Rate = employee.Rate;
		p.Compensation = monthlyRate;
		params.Employees.Add ( p );
	enddo;
	params.Date = this.Date;
	Call ( "Documents.Hiring.Create", params );
	#endregion
	
	RegisterEnvironment ( id );

EndProcedure

Function getEmployees ()

	id = this.ID;
	dateStart = this.Date - 86400;
	dateEnd = Date ( 1, 1, 1 );
	employees = new Array ();
	employees.Add ( newEmployee ( "Employee1 " + id, dateStart, dateEnd, 10000, this.Department1 ) );
	employees.Add ( newEmployee ( "Employee2 " + id, dateStart, dateEnd, 10000, this.Department2 ) );
	return employees;

EndFunction

Function newEmployee ( Name, DateStart, DateEnd, Rate, Department )

	p = new Structure ( "Name, DateStart, DateEnd, Rate, Department" );
	p.Name = Name;
	p.DateStart = DateStart;
	p.DateEnd = DateEnd;
	p.Rate = Rate;
	p.Department = Department;
	return p;

EndFunction
