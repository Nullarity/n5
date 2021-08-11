// Description:
// Create & post a new Hiring document
//
// Parameters:
// Documents.Hiring.Create.Params
//
// Returns:
// Structure ( "Date, Number" )

MainWindow.ExecuteCommand ( "e1cib/data/Document.Hiring" );
form = With ( "Hiring (cr*" );

// ***********************************
// Fill header
// ***********************************

date = _.Date;
Set ( "#Date", date );
Set ( "#Memo", _.Memo );

if ( _.Company <> undefined ) then
	Set ( "#Company", _.Company );
endif;

// ***********************************
// Fill table
// ***********************************

for each row in _.Employees do
	Click ( "#EmployeesAdd" );
	With ( "Employee" );
	
	if ( row.Put
		or row.PutAll ) then
		Put ( "#Employee", row.Employee );
	else
		selectEmployee ( row.Employee, _ );
	endif;	
	Set ( "#DateStart", row.DateStart );
	duration = row.Duration;
	if ( duration > 0 ) then
		Set ( "#Duration", duration );
	endif;
	dateEnd = row.DateEnd;
	if ( dateEnd <> undefined ) then
		Set ( "#DateEnd", dateEnd );
	endif;
	if ( row.PutAll ) then
		Put ( "#Department", row.Department );
		Put ( "#Position", row.Position );
	else
		selectDepartment ( row.Department, _ );
		selectPosition ( row.Position, _ );
	endif;
	
	schedule = row.Schedule;
	if ( schedule <> undefined ) then
		Set ( "#Schedule", schedule );
	endif;
	Put ( "#Compensation", row.Compensation );
	expenses = row.Expenses;
	if ( expenses = undefined ) then
		expenses = "Payroll, Wages";
	endif;
	Put ( "#Expenses", expenses );
	Put ( "#Rate", row.Rate );
	if ( row.InHand ) then
		Click ( "#InHand" );
	endif;
	for each rowAdditional in row.RowsAdditions do
		Click ( "#ObjectAdditionsAdd" );
		Put ( "#ObjectAdditionsCompensation", rowAdditional.Compensation );
		Put ( "#ObjectAdditionsRate", rowAdditional.Rate );
		if ( rowAdditional.InHand ) then
			table = Get ( "#ObjectAdditions" );
			table.EndEditRow ( false );
			Click ( "#ObjectAdditionsInHand" );
		endif;
	enddo;
	Click ( "#FormOK" );
	With ( form );
enddo;

// ***********************************
// Post and return
// ***********************************

Click ( "#FormPost" );
number = Fetch ( "#Number" );
Close ();
return new Structure ( "Date, Number", date, number );

// ***********************************
// Procedures
// ***********************************

Procedure selectEmployee ( Employee, _ )

	Choose ( "#Employee" );
	
	creation = Call ( "Catalogs.Employees.Create.Params" );
	creation.Description = Employee;
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Employees;
	p.Search = Employee;
	p.CreationParams = creation;
	p.CreateScenario = "Catalogs.Employees.Create";
	Call ( "Common.Select", p );

EndProcedure

Procedure selectDepartment ( Department, _ )

	Choose ( "#Department" );
	
	creation = Call ( "Catalogs.Departments.Create.Params" );
	creation.Description = Department;
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Departments;
	p.Search = Department;
	p.CreationParams = creation;
	p.CreateScenario = "Catalogs.Departments.Create";
	Call ( "Common.Select", p );

EndProcedure

Procedure selectPosition ( Position, _ )

	Choose ( "#Position" );
	
	creation = Call ( "Catalogs.Positions.Create.Params" );
	creation.Description = Position;
	p = Call ( "Common.Select.Params" );
	p.Object = Meta.Catalogs.Positions;
	p.Search = Position;
	p.CreationParams = creation;
	p.CreateScenario = "Catalogs.Positions.Create";
	try
		Call ( "Common.Select", p );
	except
		With ( "Positions" );
		Click ( "#FormChoose" );	
		With ( "Employee" );
	endtry;	

EndProcedure


