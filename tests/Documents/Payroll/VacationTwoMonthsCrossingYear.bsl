// Check vacation crossing two years

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "A0HN" );
this.Insert ( "ID", id );
getEnv ();
createEnv ();

#region payrollInDecemberWithVacation
Call("Documents.Payroll.ListByMemo", id);
With();
if (Call("Table.Count", Get("#List"))) then
	Click("#FormChange");
	With();
else
	Commando ( "e1cib/command/Document.Payroll.Create" );
	Set("#Date", "12/01/2017");
	Set("#Memo", id);
	Click("#JustSave");
endif;
Click ( "#Fill" );
With ();
table = Get ( "#UserSettings" );
GotoRow ( table, "Setting", "Department" );
Put ( "#UserSettingsValue", this.Department, table );
Click ( "#FormFill" );
Pause(3 * __.Performance);
With();
Activate("#Compensations");
// 17 days in December + 15 days in January - 1 holiday in January on _Saturday_
Check("#Compensations / #CompensationsDays [2]", 31);

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "ID", ID );
	this.Insert ( "Date", "1/01/2017" );
	years = new Array ();
	years.Add ( "2017" );
	years.Add ( "2018" );
	this.Insert ( "Years", years );
	this.Insert ( "Employee", "Employee1: " + id );
	this.Insert ( "Department", "_Department " + ID );
	this.Insert ( "VacationCompensation", "Vacation " + ID );

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	date = this.Date;
	
	#region newCompensations
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	mainCompensation = "Compensation: " + id;
	p.Description = mainCompensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	p.Description = this.VacationCompensation;
	p.Method = "Vacation";
	list = new Array ();
	list.Add ( mainCompensation );
	p.Base = list;
	Call ( "CalculationTypes.Compensations.Create", p );
	#endregion

	#region newHolidayOnWeekend
	p = Call ( "Catalogs.Holidays.Create.Params" );
	holidays = "Holidays " + id;
	p.Description = holidays;
	days = p.Days;
	holiday = Call ( "Catalogs.Holidays.Create.Day" );
	holiday.Day = Date ( 2018, 1, 6 );
	holiday.Title = "Some Holiday";
	days.Add ( holiday );
	Call ( "Catalogs.Holidays.Create", p );
	
	#region newScheduleForTwoYears
	p = Call ( "Catalogs.Schedules.Create.Params" );
	schedule = "_Schedule: " + id;
	p.Year = this.Years;
	p.Description = schedule;
	p.Holidays = holidays;
	Call ( "Catalogs.Schedules.Create", p );
	#endregion

	#region newEmployee
	employees = new Array ();
	// Employee1 main work
	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );
	With ();
	employee1Name = this.Employee;
	Put ( "#FirstName", employee1Name );
	Set("#Code", "88888" + TestingID ());
	Click("Yes", "1?:*");
	Click ( "#FormWrite" );
	employee1Main = Fetch ( "#EmployeeCode" );
	Close ();
	#endregion
	
	#region newDepartment
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = this.Department;
	Call ( "Catalogs.Departments.Create", p );
	#endregion
		
	#region newHiring
	params = Call ( "Documents.Hiring.Create.Params" );
	addEmployee ( params, employee1Main, "Accountant", this.Department, mainCompensation, schedule, date, "10000" );
	params.Date = date;
	Call ( "Documents.Hiring.Create", params );
	#endregion

	#region payrollForNovember
	Commando ( "e1cib/command/Document.Payroll.Create" );
	Set("#Date", "11/01/2017");
	Click ( "#Fill" );
	With ();
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Department" );
	Put ( "#UserSettingsValue", this.Department, table );
	Click ( "#FormFill" );
	Pause(3 * __.Performance);
	With();
	Click("#FormPostAndClose");
	#endregion
	
	#region newVacation
	Commando("e1cib/command/Document.Vacation.Create");
	Employees = Get ( "#Employees" );
	Click ( "#EmployeesAdd" );
	Employees.EndEditRow ();
	Set ( "#EmployeesEmployee", this.Employee, Employees );
	Set ( "#EmployeesDateStart", "12/15/2017", Employees );
	Set ( "#EmployeesDateEnd", "1/15/2018", Employees );
	Set ( "#EmployeesCompensation", this.VacationCompensation, Employees );
	Click ( "#FormPost" );
	#endregion

	RegisterEnvironment(id);
	
EndProcedure

Procedure addEmployee ( Params, Employee, Position, Department, Compensation, Schedule, Date, Rate )
	
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = Employee;
	p.DateStart = Date;
	p.Department = Department;
	p.Position = Position;
	p.Rate = Rate;
	p.Compensation = Compensation;
	p.Schedule = Schedule;
	p.Put = true;
	Params.Employees.Add ( p );
	
EndProcedure
