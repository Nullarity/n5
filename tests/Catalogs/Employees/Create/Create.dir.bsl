// Description:
// Creates a new Employee
//
// Returns:
// Structure ( "Code, Description" )

MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Employees" );

form = With ( "Individuals (create)" );
createUser = false;
company = undefined;
pin = "";
sin = "";

if ( _ = undefined ) then
	name = "_Employee: " + CurrentDate ();
elsif ( TypeOf ( _ ) = Type ( "Structure" ) ) then
	name = _.Description;
	createUser = _.CreateUser;
	company = _.Company;
	pin = _.PIN;
	sin = _.SIN;
else
	name = _;
endif;

Set ( "#FirstName", name );
Set ( "#PIN", pin );
Set ( "#SIN", sin );

if ( company <> undefined ) then
	Set ( "#EmployeeCompany", company );
endif;

Set("#Code", "88888" + TestingID ());
Click("Yes", "1?:*");

Click ( "#FormWrite" );
code = Fetch ( "Code" );

if ( createUser ) then
	Click ( "#CreateUser" );
	With();
	Set ("#Email", name + "@domain.com");
	Set ( "#Code", Right ( name, 3 ) );
	Click ("#FormWriteAndClose");
endif;

Close ( form );

return new Structure ( "Code, Description", code, name );

