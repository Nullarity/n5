#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var Env;
var TabDoc;
var DateStart;
var DateEnd;
var Company;
var Individual;
var Deductions;
var Taxes;
var DeductionsPeriods;
var DebtsRow;

Procedure OnCheck ( Cancel ) export
	
	readParams ();
	
EndProcedure 

Procedure readParams ()
	
	settings = Params.Composer.GetSettings ();
	Company = DC.GetParameter ( settings, "Company" ).Value;
	Individual = DC.GetParameter ( settings, "Individual" ).Value;
	try
		year = Number ( String ( DC.GetParameter ( settings, "Year" ).Value ) );
	except
		year = 1;
	endtry;
	DateStart = Date ( year, 1, 1 );
	DateEnd = EndOfYear ( DateStart );
	
EndProcedure 

Procedure AfterOutput () export

	init ();
	print ();

EndProcedure

Procedure init () 

	initEnv ();
	TabDoc = Params.Result;
	
EndProcedure

Procedure initEnv () 

	Env = new Structure ();
	SQL.Init ( Env );
	Env.Insert ( "T", GetTemplate ( "PersonalCard" ) );

EndProcedure

#Region Print

Function print ()
	
	initTabDoc ();
	getData ();
	putEmployees ();
	return true;
	
EndFunction

Procedure initTabDoc () 

	TabDoc.Clear ();
	Print.SetFooter ( TabDoc );
	TabDoc.PageOrientation = PageOrientation.Portrait;
	TabDoc.FitToPage = true;

EndProcedure

Procedure getData ()
	
	sqlFields ();
	sqlEmployees ();
	sqlTaxes ();
	sqlDeductions ();
	getTables ();
	employees = Env.Employees;
	if ( employees.Count () = 0 ) then
		return;
	endif;
	sqlDebts ( employees );
	getDebts ();
	indexTables ();
	
EndProcedure

Procedure sqlFields ()
	
	s = "
	|// @Fields
	|select Companies.Description as Company, Companies.CodeFiscal as CodeFiscal, Individuals.Description as EmployeeName,
	|	Individuals.PIN as EmployeePIN, Individuals.Address as EmployeeAddress, Marital.PIN as SpousePIN, 
	|	isnull ( Salary.Value, value ( ChartOfAccounts.General._5312 ) ) as PayrollAccount
	|from Catalog.Companies as Companies
	|	//
	|	//	Individuals
	|	//
	|	left join Catalog.Individuals as Individuals
	|	on Individuals.Ref = &Individual
	|	//
	|	//	MaritalStatuses
	|	//
	|	left join InformationRegister.MaritalStatuses.SliceLast ( &DateEnd, Individual = &Individual ) as Marital
	|	on Marital.Status = value ( Enum.MaritalStatuses.Married )
	|	//
	|	//	Salary
	|	//
	|	left join InformationRegister.Settings.SliceLast ( &DateStart, Parameter = value ( ChartOfCharacteristicTypes.Settings.DepositLiabilities ) ) as Salary
	|	on true
	|where Companies.Ref = &Company
	|";
 	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlEmployees ()
	
	s = "// WorkHere
	|select Employments.Employee as Employee
	|into WorkHere
	|from InformationRegister.Employment.SliceLast ( &DateStart, Employee.Individual = &Individual ) as Employments
	|where Employments.Employment in ( value ( Enum.Employment.Main ), value ( Enum.Employment.SecondJob ) )
	|union
	|select Employments.Employee
	|from InformationRegister.Employment as Employments
	|where Employments.Period between &DateStart and &DateEnd
	|and Employments.Employee.Individual = &Individual
	|and Employments.Employment in ( value ( Enum.Employment.Main ), value ( Enum.Employment.SecondJob ) )
	|index by Employee
	|;
	|// Employment
	|select Employees.Employee as Employee, &DateStart as Period, Employees.Hired as Hired
	|into Employment
	|from InformationRegister.Employees.SliceLast ( &DateStart, Employee.Individual = &Individual ) as Employees
	|where Employees.Hired
	|and Employees.Employee in ( select Employee from WorkHere )
	|union
	|select Employees.Employee, Employees.Period, Employees.Hired
	|from InformationRegister.Employees as Employees
	|where Employees.Period > &DateStart and Employees.Period <= &DateEnd
	|and Employees.Employee.Individual = &Individual
	|and Employees.Employee in ( select Employee from WorkHere )
	|index by Employee
	|;
	|// Employees
	|select Employment.Employee as Employee, max ( Employment.Period ) as DateStart,
	|	max ( isnull ( Terminated.Period, &DateEnd ) ) as DateEnd, max ( isnull ( Terminated.Period, datetime ( 1, 1, 1 ) ) ) as FireDate
	|into Employees
	|from Employment as Employment
	|	//
	|	// Terminated
	|	//
	|	left join Employment as Terminated
	|	on Terminated.Employee = Employment.Employee
	|	and Terminated.Period > Employment.Period
	|	and not Terminated.Hired
	|where Employment.Hired
	|group by Employment.Employee
	|index by Employee
	|;
	|// #Employees
	|select Employees.Employee as Employee, Employees.DateEnd as DateEnd,
	|	Employees.DateStart as HireDate, Employees.FireDate as FireDate
	|from Employees as Employees
	|order by Employees.DateStart
	|";
 	Env.Selection.Add ( s );    
	
EndProcedure

Procedure sqlTaxes () 

	s = "
	|// Taxes
	|select Taxes.Employee as Employee, Taxes.Ref as Ref, Taxes.Date as Date, sum ( Taxes.Deductions ) as Deductions,
	|	sum ( Taxes.MedicalBase ) as MedicalBase, sum ( Taxes.Medical ) as Medical,
	|	sum ( Taxes.IncomeTaxBase ) as IncomeTaxBase, sum ( Taxes.IncomeTax ) as IncomeTax
	|into Taxes	
	|from (
	|	select Taxes.Employee as Employee, Taxes.Ref as Ref, Taxes.Date as Date, Taxes.Deductions as Deductions,
	|		case when Taxes.Method = value ( Enum.Calculations.MedicalInsurance ) then Taxes.Base else 0 end as MedicalBase,
	|		case when Taxes.Method = value ( Enum.Calculations.MedicalInsurance ) then Taxes.Result else 0 end as Medical,
	|		case when Taxes.Method = value ( Enum.Calculations.IncomeTax ) then Taxes.Base else 0 end as IncomeTaxBase,
	|		case when Taxes.Method = value ( Enum.Calculations.IncomeTax ) then Taxes.Result else 0 end as IncomeTax
	|	from (
	|		select Employees.Employee as Employee, Taxes.Ref as Ref, Taxes.Ref.Date as Date, Taxes.Deductions as Deductions,
	|			Taxes.Method as Method, Taxes.Base as Base, Taxes.Result as Result
	|		from Employees as Employees
	|			//
	|			//	Taxes
	|			//
	|			join Document.PayEmployees.Taxes as Taxes
	|			on Taxes.Ref.Posted
	|			and Taxes.Ref.Date between Employees.DateStart and Employees.DateEnd
	|			and Taxes.Employee = &Individual			
	|			and Taxes.Method in ( value ( Enum.Calculations.MedicalInsurance ), value ( Enum.Calculations.IncomeTax ) )
	|		union all
	|		select Employees.Employee, Taxes.Ref, Taxes.Ref.Date, Taxes.Deductions, Taxes.Method, Taxes.Base, Taxes.Result
	|		from Employees as Employees
	|			//
	|			//	Taxes
	|			//
	|			join Document.PayAdvances.Taxes as Taxes
	|			on Taxes.Ref.Posted
	|			and Taxes.Ref.Date between Employees.DateStart and Employees.DateEnd
	|			and Taxes.Employee = &Individual			
	|			and Taxes.Method in ( value ( Enum.Calculations.MedicalInsurance ), value ( Enum.Calculations.IncomeTax ) )
	|	) as Taxes
	|) as Taxes
	|group by Taxes.Employee, Taxes.Ref, Taxes.Date
	|;
	|// #Taxes
	|select Taxes.Employee as Employee, Taxes.Date as Date, Compensations.Amount as Income,
	|	1 + datediff ( FirstMonth.Date, Taxes.Date, month ) as Months,
	|	Taxes.Deductions as Deductions, Taxes.MedicalBase as MedicalBase, Taxes.Medical as Medical,
	|	Taxes.IncomeTaxBase as IncomeTaxBase, Taxes.IncomeTax as IncomeTax 
	|from Taxes as Taxes
	|	//
	|	// First Month
	|	//
	|	join (
	|		select Taxes.Employee as Employee, min ( Taxes.Date ) as Date
	|		from Taxes as Taxes
	|		group by Taxes.Employee
	|	) as FirstMonth
	|	on FirstMonth.Employee = Taxes.Employee
	|	//
	|	//	Compensations
	|	//
	|	left join (
	|		select Compensations.Ref as Ref, sum ( Compensations.Amount ) as Amount
	|		from Document.PayEmployees.Compensations as Compensations
	|		where Compensations.Ref in ( select distinct Ref from Taxes where Ref refs Document.PayEmployees )
	|		and Compensations.Employee = &Individual
	|		group by Compensations.Ref
	|		union all
	|		select Compensations.Ref, sum ( Compensations.Result )
	|		from Document.PayAdvances.Compensations as Compensations
	|		where Compensations.Ref in ( select distinct Ref from Taxes where Ref refs Document.PayAdvances )
	|		and Compensations.Individual = &Individual
	|		group by Compensations.Ref
	|	) as Compensations
	|	on Compensations.Ref = Taxes.Ref
	|order by Taxes.Employee, Taxes.Date
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure sqlDeductions () 

	s = "
	|// Calendar
	|select Period as Period
	|into Calendar
	|from (
	|	select &DateStart as Period
	|	union all
	|	select dateadd ( &DateStart, month, 1 )
	|	union all
	|	select dateadd ( &DateStart, month, 2 )
	|	union all
	|	select dateadd ( &DateStart, month, 3 )
	|	union all
	|	select dateadd ( &DateStart, month, 4 )
	|	union all
	|	select dateadd ( &DateStart, month, 5 )
	|	union all
	|	select dateadd ( &DateStart, month, 6 )
	|	union all
	|	select dateadd ( &DateStart, month, 7 )
	|	union all
	|	select dateadd ( &DateStart, month, 8 )
	|	union all
	|	select dateadd ( &DateStart, month, 9 )
	|	union all
	|	select dateadd ( &DateStart, month, 10 )
	|	union all
	|	select dateadd ( &DateStart, month, 11 )
	|	) as Calendar
	|where Calendar.Period between &DateStart and &DateEnd
	|index by Period
	|;
	|// DeductionRates
	|select &DateStart as Period, Deductions.Deduction as Deduction, Deductions.Rate as Rate
	|into DeductionRates
	|from InformationRegister.DeductionRates.SliceLast ( &DateStart ) as Deductions
	|union all
	|select Deductions.Period, Deductions.Deduction, Deductions.Rate
	|from InformationRegister.DeductionRates as Deductions
	|where Deductions.Period > &DateStart and Deductions.Period <= &DateEnd
	|index by Period
	|;
	|// DeductionsList
	|select Calendar.Period as Period, Deductions.Deduction as Deduction, Deductions.Rate as Rate
	|into DeductionsList
	|from Calendar as Calendar
	|	//
	|	// DeductionPeriods
	|	//
	|	join (
	|		select Calendar.Period as Period, Deductions.Deduction as Deduction, max ( Deductions.Period ) as DeductionPeriod
	|		from Calendar as Calendar
	|			//
	|			// Deductions
	|			//
	|			left join DeductionRates as Deductions
	|			on Deductions.Period <= Calendar.Period
	|		group by Calendar.Period, Deductions.Deduction
	|	) as DeductionPeriods
	|	on DeductionPeriods.Period = Calendar.Period
	|	//
	|	// DeductionRate
	|	//
	|	join DeductionRates as Deductions
	|	on Deductions.Deduction = DeductionPeriods.Deduction
	|	and Deductions.Period = DeductionPeriods.DeductionPeriod
	|index by Period, Deduction	
	|;
	|// EmployeeDeductions
	|select &DateStart as Period, true as Use, Deductions.Deduction as Deduction
	|into EmployeeDeductions
	|from InformationRegister.Deductions.SliceLast ( &DateStart, Employee.Individual = &Individual ) as Deductions
	|where Deductions.Use
	|union all
	|select Deductions.Period, Deductions.Use, Deductions.Deduction
	|from InformationRegister.Deductions as Deductions
	|where Employee.Individual = &Individual
	|and Deductions.Period > &DateStart and Deductions.Period <= &DateEnd
	|index by Period
	|;
	|// EmployeeDeductionPeriods
	|select Calendar.Period as Period, Deductions.Deduction as Deduction,
	|	max ( Deductions.Period ) as DeductionPeriod
	|into EmployeeDeductionPeriods
	|from Calendar as Calendar
	|	//
	|	// Deductions
	|	//
	|	left join EmployeeDeductions as Deductions
	|	on Deductions.Period <= Calendar.Period
	|group by Calendar.Period, Deductions.Deduction
	|index by Period
	|;
	|// Deductions
	|select Calendar.Period as Period, Deductions.Deduction as Deduction,
	|	sum ( case when Deductions.Use then DeductionsList.Rate / 12 else 0 end ) as Amount
	|into Deductions	
	|from Calendar as Calendar
	|	//
	|	// DeductionPeriods
	|	//
	|	join EmployeeDeductionPeriods as DeductionPeriods
	|	on DeductionPeriods.Period = Calendar.Period
	|	//
	|	// Deductions
	|	//
	|	join EmployeeDeductions as Deductions
	|	on Deductions.Period = DeductionPeriods.DeductionPeriod
	|	and Deductions.Deduction = DeductionPeriods.Deduction
	|	//
	|	// DeductionsList
	|	//
	|	join DeductionsList as DeductionsList
	|	on DeductionsList.Period = Calendar.Period
	|	and DeductionsList.Deduction = Deductions.Deduction
	|group by Calendar.Period, Deductions.Deduction
	|;
	|// DeductionsRecords
	|select Deductions.Deduction as Deduction, Deductions.Period as Period
	|into DeductionsRecords	
	|from ( select Deductions.Deduction as Deduction,
	|			isnull ( DeductionsRecords.Period, case when Deductions.Period < &DateStart then &DateStart else Deductions.Period end ) as Period
	|		from InformationRegister.Deductions.SliceLast ( &DateEnd, Employee.Individual = &Individual ) as Deductions
	|			//
	|			// DeductionsRecords
	|			//
	|			left join InformationRegister.Deductions as DeductionsRecords
	|			on DeductionsRecords.Period between &DateStart and &DateEnd
	|			and DeductionsRecords.Employee.Individual = &Individual
	|			and DeductionsRecords.Deduction = Deductions.Deduction
	|			and DeductionsRecords.Use
	|		union all
	|		select Deductions.Deduction, max ( Deductions.Period )
	|		from Employees as Employees
	|			//
	|			//	Deductions
	|			//
	|			left join Deductions as Deductions
	|			on Deductions.Period <= Employees.DateStart
	|		group by Deductions.Deduction
	|		) as Deductions
	|group by Deductions.Deduction, Deductions.Period
	|;
	|// #DeductionsPeriods
	|select top 6 DeductionsRecords.Period as Date, sum ( ( datediff ( DeductionsRecords.Period, &DateEnd, month ) + 1 ) * Deductions.Amount ) as Amount,
	|	Employees.Employee as Employee 
	|from DeductionsRecords as DeductionsRecords
	|	//
	|	// Deductions
	|	//
	|	join Deductions as Deductions
	|	on Deductions.Deduction = DeductionsRecords.Deduction
	|	and Deductions.Period = DeductionsRecords.Period
	|	//
	|	// Employees
	|	//
	|	left join Employees as Employees
	|	on DeductionsRecords.Period between Employees.DateStart and Employees.DateEnd
	|group by DeductionsRecords.Period, Employees.Employee	
	|order by DeductionsRecords.Period
	|;
	|// #Deductions
	|select month ( Deductions.Period ) as Month, Employees.Employee as Employee, sum ( Deductions.Amount ) as Amount
	|from Employees as Employees
	|	//
	|	//	Deductions
	|	//
	|	join Deductions as Deductions
	|	on Deductions.Period between Employees.DateStart and Employees.DateEnd
	|group by Deductions.Period, Employees.Employee
	|order by Deductions.Period
	|";
	Env.Selection.Add ( s );

EndProcedure

Procedure getTables () 

	q = Env.Q;
	q.SetParameter ( "Company", Company );
	q.SetParameter ( "Individual", Individual );
	q.SetParameter ( "DateStart", DateStart );
	q.SetParameter ( "DateEnd", DateEnd );
	SQL.Perform ( Env );

EndProcedure

Procedure sqlDebts ( Employees ) 

	q = Env.Q;
	i = 1;
	last = Employees.Count ();
	s = "
	|// #Debts";
	for each row in Employees do
		s = s + "
		|select Employees.Employee as Employee, isnull ( LastYearDebts.AmountBalanceCr, 0 ) as LastYearDebt, isnull ( Debts.AmountBalanceCr, 0 ) as Debt
		|from Employees as Employees
		|	//
		|	//	LastYearDebts
		|	//
		|	left join AccountingRegister.General.Balance ( &HireDate" + i + ", Account = &PayrollAccount, , ExtDimension1 = &Individual ) as LastYearDebts
		|	on true
		|	//
		|	//	Debts
		|	//
		|	left join AccountingRegister.General.Balance ( &DateEnd" + i + ", Account = &PayrollAccount, , ExtDimension1 = &Individual ) as Debts
		|	on true
		|where Employees.Employee = &Employee" + i + "
		|";
		q.SetParameter ( "Employee" + i, row.Employee );
		q.SetParameter ( "HireDate" + i, row.HireDate );
		q.SetParameter ( "DateEnd" + i, row.DateEnd );
		if ( i < last ) then
			s = s + "union all";
		endif;
		i = i + 1;
	enddo;
	Env.Selection.Add ( s );

EndProcedure

Procedure getDebts ()
	
	q = Env.Q;
	q.SetParameter ( "PayrollAccount", Env.Fields.PayrollAccount );
	SQL.Perform ( Env );
	
EndProcedure

Procedure indexTables () 

	Env.Deductions.Indexes.Add ( "Employee" );
	Env.Taxes.Indexes.Add ( "Employee" );
	Env.DeductionsPeriods.Indexes.Add ( "Employee" );

EndProcedure

Procedure putEmployees () 

	employees = Env.Employees;
	if ( employees.Count () = 0 ) then
		return;
	endif;
	filter = new Structure ( "Employee" );
	deductionsAll = Env.Deductions;
	taxesAll = Env.Taxes;
	deductionsPeriodsAll = Env.DeductionsPeriods;
	debts = Env.Debts;
	for each row in employees do
		employee = row.Employee;
		filter.Employee = employee;
		Deductions = deductionsAll.Copy ( filter );
		Taxes = taxesAll.Copy ( filter );
		DeductionsPeriods = deductionsPeriodsAll.Copy ( filter );
		DebtsRow = debts.Find ( employee, "Employee" );
		putHeader ( row );
		putRow ();
		TabDoc.PutHorizontalPageBreak ();
	enddo;

EndProcedure

Procedure putHeader ( Row ) 

	area = Env.T.GetArea ( "Header" );
	p = area.Parameters;
	p.Year = Format ( DateStart, "DF=yyyy" );
	FillPropertyValues ( p, Env.Fields );
	FillPropertyValues ( p, Row );
	FillPropertyValues ( p, DebtsRow );
	putDeductionsPeriods ( p );
	putDeductions ( p );
	TabDoc.Put ( area );

EndProcedure

Procedure putDeductionsPeriods ( Params ) 

	i = 1;
	total = 0;
	for each row in DeductionsPeriods do
		Params [ "DeductionDate" + i ] = row.Date;
		Params [ "DeductionsAmount" + i ] = row.Amount;
		i = i + 1;
		total = total + row.Amount;
	enddo;
	Params.TotalDeductions = total;

EndProcedure

Procedure putDeductions ( Params ) 

	for each row in Deductions do
		Params [ "Deductions" + row.Month ] = row.Amount;
	enddo;

EndProcedure

Procedure putRow () 

	area = Env.T.GetArea ( "Row" );
	p = area.Parameters;
	totalIncome = 0;
	medicalBase = 0;
	medical = 0;
	calculatedTax = 0;
	for each row in Taxes do
		FillPropertyValues ( p, row );
		income = row.Income;
		p.Income = income;
		p.TotalIncome = total ( totalIncome, income );
		p.MedicalBase = total ( medicalBase, row.MedicalBase );
		p.Medical = total ( medical, row.Medical );
		p.IncomeTaxBase = row.IncomeTaxBase;
		tax = row.IncomeTax;
		p.IncomeTax = tax;
		p.CalculatedIncomeTax = total ( calculatedTax, tax );		
		TabDoc.Put ( area );
	enddo;

EndProcedure

Function total ( Total, Amount ) 

	Total = Total + Amount;
	return Total;

EndFunction

#EndRegion

#endif