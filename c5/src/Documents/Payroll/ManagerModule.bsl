#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.Payroll.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	commitCompensations ( Env );
	commitTaxes ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	sqlCompensations ( Env );
	sqlTaxes ( Env );
	getFields ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company
	|from Document.Payroll as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlCompensations ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.Account as Account, Compensations.Compensation as Compensation,
	|	Compensations.Compensation.Description as Description, Compensations.Individual as Employee,
	|	Compensations.Department as Department, ExpenseMethods.Account as ExpenseAccount,
	|	ExpenseMethods.Expense as Expense, sum ( ExpenseMethods.Rate * Compensations.AccountingResult ) as Result
	|from Document.Payroll.Compensations as Compensations
	|	//
	|	// ExpenseMethods
	|	//
	|	join Catalog.ExpenseMethods.Expenses as ExpenseMethods
	|	on ExpenseMethods.Ref = Compensations.Expenses
	|where Compensations.Ref = &Ref
	|group by Compensations.Account, Compensations.Individual, Compensations.Department,
	|	Compensations.Compensation, ExpenseMethods.Expense, ExpenseMethods.Account
	|having sum ( ExpenseMethods.Rate * Compensations.AccountingResult ) <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlTaxes ( Env )
	
	s = "
	|// #Taxes
	|select Taxes.Account as Account, Taxes.Tax.Description as Description,
	|	Taxes.Department as Department, ExpenseMethods.Account as AccountDr,
	|	ExpenseMethods.Expense as DimDr1, sum ( ExpenseMethods.Rate * Taxes.Result ) as Result
	|from Document.Payroll.Taxes as Taxes
	|	//
	|	// ExpenseMethods
	|	//
	|	join Catalog.ExpenseMethods.Expenses as ExpenseMethods
	|	on ExpenseMethods.Ref = Taxes.Expenses
	|where Taxes.Ref = &Ref
	|group by Taxes.Account, Taxes.Tax, Taxes.Department, ExpenseMethods.Account, ExpenseMethods.Expense
	|having sum ( ExpenseMethods.Rate * Taxes.Result ) <> 0
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure 

Procedure commitCompensations ( Env )
	
	Env.Insert ( "Buffer", GeneralRecords.Frame () );
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Buffer;
	for each row in Env.Compensations do
		p.AccountDr = row.ExpenseAccount;
		p.DimDr1 = row.Expense;
		p.DimDr2 = row.Department;
		p.AccountCr = row.Account;
		p.Amount = row.Result;
		p.DimCr1 = row.Employee;
		p.DimCr2 = row.Compensation;
		p.Content = row.Description;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure 

Procedure commitTaxes ( Env )
	
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Buffer;
	for each row in Env.Taxes do
		p.AccountDr = row.AccountDr;
		p.AccountCr = row.Account;
		p.Amount = row.Result;
		p.DimDr1 = row.DimDr1;
		p.DimDr2 = row.Department;
		p.Content = row.Description;
		GeneralRecords.Add ( p );
	enddo; 
	
EndProcedure 

Procedure flagRegisters ( Env )
	
	general = Env.Registers.General;
	GeneralRecords.Flush ( general, Env.Buffer );
	general.Write = true;
	
EndProcedure

#endregion

#region Printing

Function Print ( Params, Env ) export
	
	if ( Params.Template = "Payroll" ) then
		printPayroll ( Params, Env );	
	elsif ( Params.Template = "Sickness" ) then	
		printSickness ( Params, Env );
	elsif ( Params.Template = "Vacations" ) then	
		printVacations ( Params, Env );
	endif;
	return true;
	
EndFunction

Procedure printPayroll ( Params, Env )
	
	tabDoc = Params.TabDoc;
	Print.SetFooter ( tabDoc );
	setPayrollPageSettings ( Params );
	setPayrollDataParams ( Params, Env );
	Print.OutputSchema ( Env.T, tabDoc );
	
EndProcedure

Procedure setPayrollPageSettings ( Params )
	
	tabDoc = Params.TabDoc;
	tabDoc.FitToPage = true;
	tabDoc.PageOrientation = PageOrientation.Landscape;	
	
EndProcedure 

Procedure setPayrollDataParams ( Params, Env )
	
	Env.T.Parameters.Ref.Value = Params.Reference;
	
EndProcedure 

Procedure printSickness ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableRow" );
	p = area.Parameters; 
	getSicknessPrintData ( Params, Env );
	for each row in Env.Compensations do
		putSicknessHeader ( row, Params, Env );
		base = Env.Base.Copy ( new Structure ( "Document, Employee", row.Reference, row.EmployeeRef ) );
		lineNumber = 1;
		for each baseRow in base do
			p.Fill ( baseRow );
			p.LineNumber = lineNumber;
			tabDoc.Put ( area );
			lineNumber = lineNumber + 1;
		enddo;
		putSicknessFooter ( base, Params, Env );
	enddo;
	
EndProcedure

Procedure getSicknessPrintData ( Params, Env )
	
	sqlSicknessPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlSicknessPrintData ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.Reference as Reference, Compensations.DateStart as DateStart, Compensations.DateEnd as DateEnd,
	|	Compensations.Days as SickDays, Compensations.BaseAmount as BaseAmount, Compensations.BaseAnnualBonuses as AnnualBonuses,
	|	Compensations.BaseDays as WorkedDays, Compensations.BaseHolidays as BaseHolidays, Compensations.BasePeriod as CalendarDays,
	|	Compensations.BaseQuarterlyBonuses as QuarterlyBonuses, Compensations.BaseScheduledDays as ScheduledDays,
	|	Compensations.Bonuses as Bonuses, Compensations.DailyRate as DailyRate, Compensations.Schedule.AverageDays as AverageDays,
	|	cast ( Seniority.Value as Number ( 5, 2 ) ) / 100 as SeniorityAmendment, Compensations.Result as Result, Compensations.Employee as EmployeeRef,
	|	cast ( Compensations.BaseAmount / Compensations.BaseDays + Compensations.Bonuses as Number ( 15, 2 ) ) as AverageDailyIncome,
	|	Compensations.Employee.Description as Employee
	|from Document.Payroll.Compensations as Compensations
	|	//
	|	// Seniority
	|	//
	|	left join InformationRegister.Settings.SliceLast ( &Date,
	|		Parameter = value ( ChartOfCharacteristicTypes.Settings.SeniorityAmendment )
	|	) as Seniority
	|	on true
	|where Compensations.Ref = &Ref
	|and Compensations.Compensation.Method = value ( Enum.Calculations.SickDays )
	|;
	|// #Base
	|select Base.Document as Document, Base.Employee as Employee, 
	|	Base.Period as Period, Base.Days as Days, Base.Bonuses as Bonuses, 
	|	Base.Amount as Amount, Base.ScheduledDays as ScheduledDays
	|from Document.Payroll.Base as Base
	|where Base.Ref = &Ref
	|order by Period
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putSicknessHeader ( Row, Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableHeader" );
	p = area.Parameters;
	p.Employee = Row.Employee;
	p.DateStart = Format ( Row.DateStart, "DLF=D" );
	p.DateEnd = Format ( Row.DateEnd, "DLF=D" );
	p.SickDays = Row.SickDays;
	p.BaseHolidays = Row.BaseHolidays;
	p.AverageDays = Row.AverageDays;
	p.AverageIncome = getAverageIncome ( Row );
	p.DailyRate = getDailyRate ( Row );
	p.Result = getSicknessResult ( Row );
	tabDoc.Put ( area );
	
EndProcedure

Function getAverageIncome ( Row )
	
	p = new Structure ( "BaseAmount, WorkedDays, Bonuses, QuarterlyBonuses, AnnualBonuses, AverageDays, AverageDailyIncome" );
	FillPropertyValues ( p, Row );
	return Output.AverageIncome ( p );
	
EndFunction

Function getDailyRate ( Row )
	
	p = new Structure ( "AverageDailyIncome, ScheduledDays, CalendarDays, BaseHolidays, DailyRate" );
	FillPropertyValues ( p, Row );
	return Output.DailyRate ( p );	
	
EndFunction

Function getSicknessResult ( Row )
	
	p = new Structure ( "DailyRate, SickDays, SeniorityAmendment, Result" );
	FillPropertyValues ( p, Row );
	return Output.SicknessResult ( p );	
	
EndFunction

Procedure putSicknessFooter ( Table, Params, Env )
	
	t = Env.T;
	area = t.GetArea ( "TableFooter" );
	p = area.Parameters;
	p.Amount = Table.Total ( "Amount" );
	p.Bonuses = Table.Total ( "Bonuses" );
	Params.TabDoc.Put ( area );
	
EndProcedure

Procedure printVacations ( Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableRow" );
	p = area.Parameters;
	getVacationsPrintData ( Params, Env );
	for each row in Env.Compensations do
		putVacationsHeader ( row, Params, Env );
		base = Env.Base.Copy ( new Structure ( "Document, Employee", row.Reference, row.EmployeeRef ) );
		lineNumber = 1;
		for each baseRow in base do
			p.Fill ( baseRow );
			p.LineNumber = lineNumber;
			tabDoc.Put ( area );
			lineNumber = lineNumber + 1;
		enddo;
		putVacationsFooter ( base, Params, Env );
	enddo;
	
EndProcedure

Procedure getVacationsPrintData ( Params, Env )
	
	sqlVacationsPrintData ( Env );
	Env.Q.SetParameter ( "Ref", Params.Reference );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlVacationsPrintData ( Env )
	
	s = "
	|// #Compensations
	|select Compensations.Reference as Reference, Compensations.DateStart as DateStart, Compensations.DateEnd as DateEnd,
	|	Compensations.Days as VacationDays, Compensations.BaseAmount as BaseAmount, Compensations.BaseAnnualBonuses as AnnualBonuses,
	|	Compensations.BaseDays as WorkedDays, Compensations.BaseHolidays as BaseHolidays, Compensations.BasePeriod as CalendarDays,
	|	Compensations.BaseQuarterlyBonuses as QuarterlyBonuses, Compensations.BaseScheduledDays as ScheduledDays,
	|	Compensations.Bonuses as Bonuses, Compensations.DailyRate as DailyRate, Compensations.Schedule.AverageDays as AverageDays,
	|	Compensations.Result as Result, Compensations.Employee as EmployeeRef, Compensations.Holidays as Holidays,
	|	cast ( Compensations.BaseAmount / Compensations.BaseDays + Compensations.Bonuses as Number ( 15, 2 ) ) as AverageDailyIncome,
	|	Compensations.Employee.Description as Employee
	|from Document.Payroll.Compensations as Compensations
	|where Compensations.Ref = &Ref
	|and Compensations.Compensation.Method = value ( Enum.Calculations.Vacation )
	|;
	|// #Base
	|select Base.Document as Document, Base.Employee as Employee, Base.Period as Period,
	|	Base.Days as Days, Base.Bonuses as Bonuses, Base.Amount as Amount,
	|	Base.ScheduledDays as ScheduledDays
	|from Document.Payroll.Base as Base
	|where Base.Ref = &Ref
	|order by Period
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure putVacationsHeader ( Row, Params, Env )
	
	t = Env.T;
	tabDoc = Params.TabDoc;
	area = t.GetArea ( "TableHeader" );
	p = area.Parameters;
	p.Employee = Row.Employee;
	p.DateStart = Format ( Row.DateStart, "DLF=D" );
	p.DateEnd = Format ( Row.DateEnd, "DLF=D" );
	p.VacationDays = Row.VacationDays;
	p.VacationDaysPlusHolidays = Row.VacationDays + Row.Holidays; 
	p.BaseHolidays = Row.BaseHolidays;
	p.AverageDays = Row.AverageDays;
	p.AverageIncome = getAverageIncome ( Row );
	p.DailyRate = getDailyRate ( Row );
	p.Result = getVacationsResult ( Row );
	tabDoc.Put ( area );
	
EndProcedure

Function getVacationsResult ( Row )
	
	p = new Structure ( "DailyRate, VacationDays, Result" );
	FillPropertyValues ( p, Row );
	return Output.VacationsResult ( p );	
	
EndFunction

Procedure putVacationsFooter ( Table, Params, Env )
	
	t = Env.T;
	area = t.GetArea ( "TableFooter" );
	p = area.Parameters;
	p.Amount = Table.Total ( "Amount" );
	p.Bonuses = Table.Total ( "Bonuses" );
	Params.TabDoc.Put ( area );
	
EndProcedure

#endregion

#endif