// Unload salary to banking application
// - Pay salary
// - Create payment order
// - Unload data

Call ( "Common.Init" );
CloseAll ();

this.Insert ( "ID", Call ( "Common.ScenarioID", "A0CE" ) );
getEnv ();
createEnv ();

#region unloadData
Commando("e1cib/app/DataProcessor.UnloadPayments");
Put ("#Account", this.ID);
Click("#MarkAll");
Click("#FormUnload");
Pause ( __.Performance * 4 );
#endregion

#region testResults
text = new TextDocument();
text.Read ( this.SalaryFile );
Assert(text.GetLine ( 1 )).Equal ("TAB_NO,NAME_EM,TR_AMOUNT,KV");
Assert(text.GetLine ( 2 )).Equal ("88888A0CF," + this.Employee + "/,10000.00,498");
#endregion

// *************************
// Procedures
// *************************

Procedure getEnv ()

	id = this.ID;
	this.Insert ( "Date", BegOfMonth ( CurrentDate() ) );
	this.Insert ( "BankOrganization", "Bank " + id );
	this.Insert ( "Employee", "Employee " + id );
	this.Insert ( "MonthlyRate", "Monthly " + id );
	this.Insert ( "Rate", 10000 );
	this.Insert ( "PaymentsFile", __.Files + "Unload/payments.txt");
	this.Insert ( "SalaryFile", __.Files + "Unload/salary.csv");

EndProcedure

Procedure createEnv ()

	id = this.ID;
	if ( EnvironmentExists ( id ) ) then
		return;
	endif;
	
	#region newBankOrganization
	p = Call("Catalogs.Customers.Create.Params");
	p.Name = this.BankOrganization;
	p.BankAccount = this.ID;
	Call("Catalogs.Customers.Create", p);
	#endregion

	#region newEmployee
	p = Call ( "Catalogs.Employees.Create.Params" );
	p.Description = this.Employee;
	Call ( "Catalogs.Employees.Create", p );
	#endregion

	#region newCompensations
	p = Call ( "CalculationTypes.Compensations.Create.Params" );
	compensation = this.MonthlyRate;
	p.Description = compensation;
	p.Method = "Monthly Rate";
	Call ( "CalculationTypes.Compensations.Create", p );
	#endregion

	#region Hiring
	monthlyRate = this.MonthlyRate;
	params = Call ( "Documents.Hiring.Create.Params" );
	p = Call ( "Documents.Hiring.Create.Row" );
	p.Employee = this.Employee;
	p.DateStart = Format ( this.Date, "DLF=D" ); 
	p.Position = "Director";
	p.Rate = this.Rate;
	p.Compensation = this.MonthlyRate;
	params.Employees.Add ( p );
	params.Date = this.Date;
	Call ( "Documents.Hiring.Create", params );
	#endregion
	
	#region payroll
	Commando ( "e1cib/data/Document.Payroll" );
	documentDate = Date ( Fetch ( "#DateStart" ) );
	date = this.Date;
	direction = ? ( documentDate < date, 1, -1 );
	breaker = 1;
	while ( breaker < 99 ) do
		dateStart = Date ( Fetch ( "#DateStart" ) );
		if ( dateStart = date ) then
			break;
		else
			Click ( ? ( direction = 1, "#NextPeriod", "#PreviousPeriod" ) );
		endif;
		breaker = breaker + 1;
	enddo;
	Activate ( "#Totals" );
	Click ( "#Fill" );
	With ();
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Employee" );
	Put ( "#UserSettingsValue", this.Employee, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 4 );
	With ();
	Click("#FormPost");
	#endregion
	
	#region pay
	Commando("e1cib/command/Document.PayEmployees.Create");
	Put("#Date", Format (EndOfMonth (this.Date), "DLF=D" ));
	Activate("#BankAccount").Create ();
	With();
	Set ( "#AccountNumber", this.ID );
	Set ( "#Account", "2421" );
	Pick ( "#Application", "Eximbank" );
	Set ( "#Unloading", this.PaymentsFile );
	Set ( "#UnloadingSalary", this.SalaryFile );
	Click("#FormWriteAndClose");
	With();
	Click("#Fill");
	With ();
	table = Get ( "#UserSettings" );
	GotoRow ( table, "Setting", "Employee" );
	Put ( "#UserSettingsValue", this.Employee, table );
	Click ( "#FormFill" );
	Pause ( __.Performance * 4 );
	With ();
	Click("#FormPost");
	#endregion

	#region paymentOrder
	Click ( "#PaymentOrder" );
	With ();
	Put ("#Recipient", this.BankOrganization);
	Click ( "#FormWriteAndClose" );
	#endregion
	
	RegisterEnvironment ( id );

EndProcedure
