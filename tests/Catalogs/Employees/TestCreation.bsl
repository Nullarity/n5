Call ( "Common.Init" );
CloseAll ();

env = getEnv ();
date = env.Date;

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Employees" );
list = With ( "Employees" );
Click ( "#FormCreate" );

With ( "Individuals (cr*" );
fill ( Env );

Click ( "#FormWrite" );
Click ( "#FormWrite" ); // Second time

// Check Deductions
Click ( "Deductions", GetLinks () );
deductions = With ( "Deductions" );
Click ( "#ListCreate" );
With ( "Deductions (cr*" );
CheckState ( "#Employee", "ReadOnly" );
Close ();
With ( deductions );
Click ( "#UnusedDeductionsCreate" );
With ( "Unused Deductions (cr*" );
CheckState ( "#Employee", "ReadOnly" );
Set ( "#Year", Format ( Year ( date ), "NG=" ) );
Set ( "#Amount", 500 );
Click ( "#FormWriteAndClose" );

// Create & cancel deduction
deductions = With ( "Deductions" );
Click ( "#ListCreate" );
With ( "Deductions (cr*" );
Put ( "#Deduction", "P" );
Click ( "#FormWriteAndClose" );
With ( deductions );
Click ( "#DeductionsCancel" );
With ( "Deductions (cr*" );
Set ( "#Period", Format ( AddMonth ( date, 1 ), "DF='MM/yyyy'" ) );
Click ( "#FormWriteAndClose" );

// Click Show Actual and Go back
With ( deductions );
Click ( "#ListShowActual" );
Click ( "#ActualDeductionsShowRecords" );

// Create a new IncomeTax methos
Click ( "#IncomeTaxCreate" );

// *************************
// Procedures
// *************************

Function getEnv ()

	id = Call ( "Common.ScenarioID", "28D3A15E" );
	p = new Structure ();
	p.Insert ( "ID", id );
	p.Insert ( "Date", CurrentDate () );
	p.Insert ( "FirstName", id );
	p.Insert ( "LastName", "L_" + id );
	p.Insert ( "Patronymic", "P_" + id );
	return p;

EndFunction

Procedure fill ( Env )

	Set ( "#FirstName", Env.FirstName );
	Set ( "#LastName", Env.LastName );
	Set ( "#Patronymic", Env.Patronymic );
	
EndProcedure
