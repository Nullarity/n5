Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2A6C88D4" );
env = getEnv ( id );
createEnv ( env );

// ***********************************
// Create Report
// ***********************************

Commando ( "e1cib/command/Catalog.Reports.Command.Show", false );
Pause ( __.Performance * 3 );
With();
Put ( "#CompanyFilter", env.Company );

Click ( "#ListCreate" );
With ( "Select Report" );
GotoRow ( "#List", "Description", "REV1" );
Click ( "#FormChoose" );
Pause ( __.Performance * 3 );

list = With ();
Get ( "#FinancialPeriodField" ).Open ();
With ( "Select period" );
Put ( "#DateBegin", env.Date );
Put ( "#DateEnd", env.Date );
Click ( "#Select" );

With ( list );
Click ( "#ReportRecalc" );
Click ( "Yes", DialogsTitle );

With ( list );
Set ( "#ReportField[R3C6:R3C33]", id );
Click ( "#FormRefreshReport" );

With ( list );
Call ( "Common.CheckLogic", "#ReportField" );

// *************************
// Procedures
// *************************

Function getEnv ( ID )
	
	p = new Structure ();
	p.Insert ( "ID", ID );
	p.Insert ( "Date", "05/31/2019" );
	p.Insert ( "Company", "Company: " + ID );
	return p;
	
EndFunction

Procedure createEnv ( Env )
	
	id = Env.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	// *************************
	// Create Company
	// *************************
	
	Call ( "Catalogs.Companies.Create", Env.Company );
	
	// *************************
	// Create Roles
	// *************************
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Accountant" );
	Put ( "#Role", "Chief Accountant" );
	Click ( "#Apply" );
	
	Commando ( "e1cib/data/Document.Roles" );
	With ( "Roles (create)" );
	Put ( "#Company", Env.Company );
	Put ( "#User", "Director" );
	Put ( "#Role", "General Manager" );
	Click ( "#Apply" );
	
	// *************************
	// Employee
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/List/Catalog.Employees" );
	With ( "Employees" );
	Click ( "#FormCreate" );
	formEmployee = With ( "Individuals (create)" );
	name = "FirstName: " + id;
	Put ( "#EmployeeCompany", Env.Company );
	Put ( "#FirstName", name );
	Put ( "#LastName", "LastName: " + id );
	Put ( "#Patronymic", "Patronymic: " + id );
	Put ( "#Birthday", "11/06/1988" );
	Put ( "#PIN", "PIN: " + id );
	Put ( "#SIN", "SIN: " + id );
	Put ( "#Code", id );
	Click ( "Yes", Forms.Get1C () );
	Click ( "#FormWrite" );
	employeeCode = id;
	
	// *************************
	// State
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.States" );
	With ( "States (create)" );
	Put ( "#Owner", "Молдавия" );
	state = "State: " + id;
	Put ( "#Description", state );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Cities
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/data/Catalog.Cities" );
	With ( "Cities (create)" );
	setValue ( "#Owner", "Молдавия", "Countries" );
	city = "City: " + id;
	Put ( "#Description", city );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// Addresses
	// *************************

	MainWindow.ExecuteCommand ( "e1cib/Data/Catalog.Addresses" );
	With ( "Addresses (create)" );
	Put ( "#Country", "Молдавия" );
	Put ( "#State", state );
	Put ( "#Municipality", "Municipality: " + id );
	Put ( "#City", city );
	Put ( "#Street", "Street: " + id );
	Put ( "#Number", "Number: " + id );
	Put ( "#Building", "Building: " + id );
	Put ( "#Entrance", "Entrance: " + id );
	Put ( "#Floor", "Floor: " + id );
	Put ( "#Apartment", "Apartment: " + id );
	Put ( "#ZIP", "12345" );
	Click ( "#Manual" );
	birthPlace = "BirthPlace: " + id;
	Put ( "#Address", birthPlace );
	setValue ( "#Owner", employeeCode, "Individuals", "Code" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// IDs
	// *************************

	With ( formEmployee );
	Put ( "#Birthplace", birthPlace );
	Click ( "#FormWrite" );
	Click ( "IDs", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 

	With ( "Identity Documents (create)" );
	Put ( "#Period", "01/01/2019" );
	Put ( "#Type", "Birth Certificate" );
	Put ( "#Issued", "01/10/1986" );
	Put ( "#IssuedBy", "IssuedBy: " + id );
	Put ( "#Series", "AA" );
	Put ( "#Number", "0001111" );
	Click ( "#FormWriteAndClose" );
	With ( name + "*" );
	
	Click ( "#FormCreate" );
	With ( "Identity Documents (create)" );
	Put ( "#Period", "01/17/2019" );
	Put ( "#Type", "Paşaport de tip vechi" );
	Put ( "#Issued", "01/01/2019" );
	Put ( "#IssuedBy", "of. 41" );
	Put ( "#Series", "AB" );
	Put ( "#Number", "25015411" );
	Click ( "#FormWriteAndClose" );
	
	// *************************
	// 	Status
	// *************************

	With ( name + "*" );
	Click ( "Status", GetLinks () );
	With ( name + "*" );
	Click ( "#FormCreate" ); 
	With ( "Marital Statuses (create)" );
	Put ( "#Period", "05/20/2019" );
	Put ( "#Status", "Married" );
	Click ( "#FormWriteAndClose" );
	
	RegisterEnvironment ( id );
	
EndProcedure

Function local ( Date1, Date2 = undefined, Date3 = undefined )
	
	if ( Date2 = undefined ) then
		date = Date1;
	else
		date = Date ( Date1, Date2, Date3 );
	endif;
	return Format ( date, "DLF = 'DT'" );
	
EndFunction

Procedure setValue ( Field, Value, Object, GoToRow = "Description" )
	
	form = CurrentSource;
	Choose ( Field );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", Object );
	Click ( "#OK" );
	With ( Object );
	GotoRow ( "#List", GoToRow, Value );
	Click ( "#FormChoose" );
	CurrentSource = form;
	
EndProcedure