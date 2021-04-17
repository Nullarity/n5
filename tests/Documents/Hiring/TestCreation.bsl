Call ( "Common.Init" );
CloseAll ();

// ***********************************
// Variables
// ***********************************

env = getEnv ();
createEnv ( env );

date = CurrentDate ();
dateStart = BegOfMonth ( date );
duration = 6;
dateEnd = AddMonth ( dateStart, duration );
department = Env.Department;
schedule = "General";

// ***********************************
// Filling
// ***********************************

MainWindow.ExecuteCommand ( "e1cib/data/Document.Hiring" );
form = With ( "Hiring (cre*" );

table = Get ( "#Employees" );
Click ( "#EmployeesAdd", table );

With ( "Employee" );

Set ( "#Employee", Env.Employee );
Set ( "#DateStart", Format ( dateStart, "DLF=D" ) );
Set ( "#Duration", 6 );
Set ( "#Department", Env.Department );
Set ( "#Position", Env.Position );
Set ( "#Compensation", Env.Compensation );
Set ( "#Expenses", Env.Expenses );
Set ( "#Rate", Env.Rate );

table = Activate ( "#ObjectAdditions" );
Click ( "#ObjectAdditionsAdd" );
Put ( "#ObjectAdditionsCompensation", Env.Bonus, table );
Set ( "#ObjectAdditionsRate", Env.BonusRate, table );

Click ( "#FormOK" );
With ( form );
Click ( "#EmployeesEdit" );
With ( "Employee" );

// ***********************************
// Check Additions table
// ***********************************

table = Activate ( "#ObjectAdditions" );
Check ( "#ObjectAdditionsCompensation", Env.Bonus, table );
Check ( "#ObjectAdditionsRate", Env.BonusRate, table );
if ( Call ( "Common.AppIsCont" ) ) then
	Check ( "#ObjectAdditionsCurrency", "MDL", table );
else
	Check ( "#ObjectAdditionsCurrency", __.LocalCurrency, table );
endif;

// ***********************************
// Check recalculation
// ***********************************

Check ( "#DateEnd", dateEnd );
Check ( "#Schedule", schedule );

Set ( "#Duration", 0 );
Next ();
Check ( "#DateEnd", "1/1/0001 12:00:00 AM" );

Clear ( "#DateEnd" );
Check ( "#Duration", "0" );

Set ( "#DateEnd", Format ( dateEnd, "DLF=D" ) );
Next ();
Check ( "#Duration", duration );

Click ( "#FormOK" );
With ( form );

// ***********************************
// Check Additions on the right panel
// ***********************************

table = Activate ( "#Additions" );
Check ( "#AdditionsCompensation", Env.Bonus, table );
Check ( "#AdditionsRate", Env.BonusRate, table );
Check ( "#AdditionsCurrency", __.LocalCurrency, table );

// ***********************************
// Post and check fields
// ***********************************

Click ( "#FormPost" );

// Copy and post again: check message about already hired employees
Click ( "#FormCopy" );
With ( "Hiring (cr*" );
IgnoreErrors = true;
Click ( "#FormPost" );
Call ( "Common.CheckPostingError", "Employee is already hired" );
Close ();
IgnoreErrors = false;

// ***********************************
// Procedures
// ***********************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "255687E3" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Employee", "_Hiring: " + id );
	p.Insert ( "Department", "_Department: " + id );
	p.Insert ( "Position", "_Position: " + id );
	p.Insert ( "Compensation", "S" + id );
	p.Insert ( "Expenses", "_Salary " + id );
	p.Insert ( "Rate", 30 );
	p.Insert ( "Bonus", "B" + id );
	p.Insert ( "BonusRate", 5 );
	return p;

EndFunction

Procedure createEnv ( Env )

	id = Env.ID;
	if ( Call ( "Common.DataCreated", id ) ) then
		return;
	endif;
	
	// *************************
	// Create Employee
	// *************************
	
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = Env.Employee;
	Call ( "Catalogs.Employees.Create", p );

	// *************************
	// Create Department
	// *************************
	
	p = Call ( "Catalogs.Departments.Create.Params" );
	p.Description = Env.Department;
	Call ( "Catalogs.Departments.Create", p );

	// *************************
	// Create Position
	// *************************
	
	p = Call ( "Catalogs.Positions.Create.Params" );
	p.Description = Env.Position;
	Call ( "Catalogs.Positions.Create", p );
	
	// *************************
	// Create Compensation
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Compensation;
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Bonus
	// *************************
	
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	p.Description = Env.Bonus;
	p.Method = "Percent";
	Call ( "CalculationTypes.Compensations.Create", p );

	// *************************
	// Create Expenses
	// *************************
	
	expenses = Env.Expenses;
	Call ( "Catalogs.Expenses.Create", expenses );
	p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
	p.Description = expenses;
	p.Expense = expenses;
	p.Account = "8111";
	Call ( "Catalogs.ExpenseMethods.Create", p );

	Call ( "Common.StampData", id );

EndProcedure
