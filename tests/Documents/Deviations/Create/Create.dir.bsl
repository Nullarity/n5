// Description:
// Creates a new Deviation Document
//
// Returns:
// Number - document number

Commando ( "e1cib/data/Document.Deviation" );
With ( "Deviation (cr*" );

for each row in _.Employees do
	Click ( "#EmployeesAdd" );
	Set ( "#EmployeesEmployee", row.Employee );
	Put ( "#EmployeesDay", row.Day );
	Put ( "#EmployeesDuration", row.Duration );
	Put ( "#EmployeesTime", row.Time );
enddo;

value = _.Memo;
if ( value <> undefined ) then
	Set ( "#Memo", value );
endif;

Click ( "#FormWrite" );
number = Fetch ( "#Number" );
Click ( "#FormPostAndClose" );
return number;