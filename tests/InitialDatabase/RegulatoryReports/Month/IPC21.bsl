Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal
	|from Catalog.Companies as Companies
	|where Companies.Ref = &Company
	|;
	|// @Taxes
	|select sum ( case when Taxes.Method in ( value ( Enum.Calculations.IncomeTax ) ) then Taxes.Result else 0 end ) as Income,
	|	sum ( case when Taxes.Method in ( value ( Enum.Calculations.MedicalInsurance ) ) then Taxes.Result else 0 end ) as Medical
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref.Posted
	|and Taxes.Ref.Date between &DateStart and &DateEnd
	|and Taxes.Ref.Company = &Company
	|;
	|// Income
	|select Incomes.Recorder as Recorder, Incomes.AccountDr as Account, Incomes.Amount as Amount,
	|	Incomes.ExtDimensionCr1 as Code
	|into Income
	|from AccountingRegister.General.RecordsWithExtDimensions ( &DateStart, &DateEnd, AccountCr.Code = ""5343""
	|and Company = &Company and ExtDimensionCr1 <> value ( Enum.IncomeCodes.EmptyRef ) , , ) as Incomes
	|;
	|// Base
	|select sum ( Turnovers.AmountTurnoverDr ) as Amount, Income.Code as Code
	|into Base
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder,
	|	Account in ( select Account from Income ), ,
	|	Company = &Company, ,  ) as Turnovers
	|	// 
	|	// Income
	|	// 
	|	left join Income as Income
	|	on Income.Recorder = Turnovers.Recorder
	|where Turnovers.Recorder in ( select Recorder from Income )
	|group by Income.Code 
	|;
	|// #Table1
	|select Income.Amount as IncomeAmount, presentation ( Income.Code ) as Code, Base.Amount as BaseAmount,
	|	case when Income.Code = value ( Enum.IncomeCodes.DOB ) then ""34""
	|		when Income.Code = value ( Enum.IncomeCodes.PL ) then ""35""
	|		when Income.Code = value ( Enum.IncomeCodes.PLs ) then ""36""
	|		when Income.Code = value ( Enum.IncomeCodes.FOL ) then ""37""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVA ) then ""38""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSA ) then ""39""
	|		when Income.Code = value ( Enum.IncomeCodes.ROY ) then ""40""
	|		when Income.Code = value ( Enum.IncomeCodes.NOR ) then ""41""
	|		when Income.Code = value ( Enum.IncomeCodes.PUB ) then ""42""
	|		when Income.Code = value ( Enum.IncomeCodes.LIV ) then ""43""
	|		when Income.Code = value ( Enum.IncomeCodes.CSM ) then ""44""
	|		when Income.Code = value ( Enum.IncomeCodes.ROYb ) then ""45""
	|		when Income.Code = value ( Enum.IncomeCodes.DOBb ) then ""46""
	|		when Income.Code = value ( Enum.IncomeCodes.CC ) then ""47""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVB ) then ""48""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSB ) then ""49""
	|		when Income.Code = value ( Enum.IncomeCodes.PLT ) then ""50""
	|		when Income.Code = value ( Enum.IncomeCodes.DONpf ) then ""52""
	|		when Income.Code = value ( Enum.IncomeCodes.AGRAC ) then ""53""
	|		else ""Continue""
	|	end as Row
	|from ( select sum ( Income.Amount ) as Amount, Income.Code as Code
	|		from Income as Income
	|		group by Income.Code
	|		) as Income
	|	// 
	|	// Base
	|	// 
	|	left join Base as Base
	|	on Base.Code = Income.Code
	|;
	|// Employees Income
	|select Payments.Employee as Employee, Payments.IncomeTax as Amount
	|into EmployeesIncome
	|from Document.PayEmployees.Totals as Payments
	|where Payments.Ref.Date between &DateStart and &DateEnd
	|and Payments.Ref.Posted
	|and PaymentS.Ref.Company = &Company
	|;
	|// #Attachment
	|// Stupidiy of moldovian IPC creators forces to do bullshit queries
	|select sum ( Income.Amount ) as Amount, Personnel.Division as Division
	|from EmployeesIncome as Income
	|	//
	|	// Departments
	|	//
	|	left join (
	|		select Personnel.Employee.Individual as Employee,
	|			max ( Personnel.Department.Division.Code ) as Division
	|		from InformationRegister.Personnel.SliceLast ( &DateEnd,
	|			Employee.Individual in ( select Employee from EmployeesIncome ) ) as Personnel
	|		group by Personnel.Employee.Individual
	|	) as Personnel
	|	on Personnel.Employee = Income.Employee
	|group by Personnel.Division
	|order by Personnel.Division
	|;
	|// Employees
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName as Name, Employees.Individual.PIN as PIN, ""01"" as Status,
	|	Employees.Individual.SIN as SIN, Employees.DateStart as Date, Employees.Individual as Individual, 
	|	Employees.Individual.Birthday as Birthday
	|into Employees	
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.Ref.Date between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|union
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName, Employees.Individual.PIN, ""02"" as Status,
	|	Employees.Individual.SIN, Employees.Date, Employees.Individual,	Employees.Individual.Birthday
	|from Document.Termination.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.Ref.Date between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|;
	|// Employee
	|select distinct Payroll.Employee as Employee
	|into PayrollEmployees
	|from Document.Payroll.Compensations as Payroll
	|where Payroll.Ref.Posted
	|and Payroll.Ref.Date between &DateStart and &DateEnd
	|and Payroll.Ref.Company = &Company
	|;
	|// Insurance
	|select Insurance.Employee as Employee, Insurance.Category as Category
	|into Insurance
	|from InformationRegister.Insurance.SliceLast ( &DateEnd, Employee in ( select distinct Employee from PayrollEmployees ) ) as Insurance
	|;
	|// Categories
	|select Settings.Parameter as Type, Settings.Value as Category
	|into Categories
	|from InformationRegister.Settings.SliceLast ( &DateEnd, Parameter in (
	|	value ( ChartOfCharacteristicTypes.Settings.ChildCare ),
	|	value ( ChartOfCharacteristicTypes.Settings.ExtendedVacation ),
	|	value ( ChartOfCharacteristicTypes.Settings.ExtraChildCare ),
	|	value ( ChartOfCharacteristicTypes.Settings.PaternityVacation ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickDays ),
	|	value ( ChartOfCharacteristicTypes.Settings.Vacation ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickDaysChild ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickOnlySocial ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickProduction ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickProductionSocial ),
	|	value ( ChartOfCharacteristicTypes.Settings.SickDaysSocial ),
	|	value ( ChartOfCharacteristicTypes.Settings.VacationWithoutPay )
	|) ) as Settings
	|;
	|// Payroll
	|select Payroll.Ref as Ref, Payroll.Employee as Employee, Payroll.Individual as Individual,
	|	Payroll.Position as Position, Payroll.DateStart as DateStart, Payroll.DateEnd as DateEnd,
	|	sum ( Payroll.AccountingResult ) as Amount, Payroll.OnCompany as OnCompany,
	|	isnull ( Categories.Category.Code, StandardCategory.Category.Code ) as Category,
	|	Payroll.Compensation as Compensation,
	|	Payroll.Compensation.Method in (
	|		value ( Enum.Calculations.SickDays ),
	|		value ( Enum.Calculations.SickDaysChild ),
	|		value ( Enum.Calculations.SickOnlySocial ),
	|		value ( Enum.Calculations.SickProduction )
	|	) as Sick
	|into Payroll
	|from Document.Payroll.Compensations as Payroll
	|	//
	|	// StandardCategory
	|	//
	|	left join Insurance as StandardCategory
	|	on StandardCategory.Employee = Payroll.Employee
	|	//
	|	// Categories
	|	//
	|	left join Categories as Categories
	|	on Categories.Type =
	|		case
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.ChildCare ) then value ( ChartOfCharacteristicTypes.Settings.ChildCare )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.ExtendedVacation ) then value ( ChartOfCharacteristicTypes.Settings.ExtendedVacation )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) then value ( ChartOfCharacteristicTypes.Settings.ExtraChildCare )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.PaternityVacation ) then value ( ChartOfCharacteristicTypes.Settings.PaternityVacation )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickDays )
	|				and Payroll.OnCompany then value ( ChartOfCharacteristicTypes.Settings.SickDays )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickDays )
	|				and not Payroll.OnCompany then value ( ChartOfCharacteristicTypes.Settings.SickDaysSocial )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.Vacation ) then value ( ChartOfCharacteristicTypes.Settings.Vacation )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickDaysChild ) then value ( ChartOfCharacteristicTypes.Settings.SickDaysChild )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickOnlySocial ) then value ( ChartOfCharacteristicTypes.Settings.SickOnlySocial )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickProduction )
	|				and Payroll.OnCompany then value ( ChartOfCharacteristicTypes.Settings.SickProduction )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.SickProduction )
	|				and not Payroll.OnCompany then value ( ChartOfCharacteristicTypes.Settings.SickProductionSocial )
	|			when Payroll.Compensation.Method = value ( Enum.Calculations.VacationWithoutPay ) then value ( ChartOfCharacteristicTypes.Settings.VacationWithoutPay )
	|		end
	|where Payroll.Ref.Posted
	|and Payroll.Ref.Date between &DateStart and &DateEnd
	|and Payroll.Ref.Company = &Company
	|group by Payroll.Ref, Payroll.Employee, Payroll.Individual, Payroll.Position, Payroll.DateStart, Payroll.DateEnd,
	|	Payroll.OnCompany, isnull ( Categories.Category.Code, StandardCategory.Category.Code ), Payroll.Compensation
	|;
	|// @Salary
	|select sum ( Payroll.Amount ) as Amount
	|from Payroll as Payroll
	|;
	|// #Table3
	|select Payroll.Employee.FirstName as FirstName, Payroll.Employee.LastName as LastName,
	|	Payroll.Individual.PIN as PIN, Payroll.Individual.SIN as SIN,
	|	Positions.ClassifierCode as PositionCode, Payroll.DateStart as DateStart, Payroll.DateEnd as DateEnd,
	|	sum ( isnull ( Taxes.Result, 0 ) ) as SocialInsurance, PayrollTaxes.Rate as Rate, Payroll.Category as Category,
	|	sum ( case when Payroll.Sick then 0 else Payroll.Amount end ) as Salary,
	|	sum ( case when Payroll.Sick then Payroll.Amount else 0 end ) as Disability
	|from Payroll as Payroll
	|	//
	|	// Taxes
	|	//
	|	left join Document.Payroll.Taxes as Taxes
	|	on Taxes.Ref = Payroll.Ref
	|	and Taxes.Employee = Payroll.Employee
	|	and Taxes.Compensation = Payroll.Compensation
	|	and Taxes.DateStart = Payroll.DateStart
	|	and Taxes.DateEnd = Payroll.DateEnd
	|	and Taxes.Method = value ( Enum.Calculations.SocialInsurance )
	|	//
	|	// PayrollTaxes
	|	//
	|	left join InformationRegister.PayrollTaxes.SliceLast ( &DateEnd,
	|		Tax.Method = value ( Enum.Calculations.SocialInsurance ) ) as PayrollTaxes
	|	on PayrollTaxes.Tax = Taxes.Tax
	|	//
	|	// Positions
	|	//
	|	left join Catalog.PositionsClassifier as Positions
	|	on Positions.Code = Payroll.Position.PositionCode
	|where Payroll.Sick
	|or not Taxes.Result is null
	|group by Payroll.Employee, Payroll.Individual, Positions.ClassifierCode, Payroll.DateStart, Payroll.DateEnd,
	|	PayrollTaxes.Rate, Payroll.Category
	|order by Payroll.Employee.Description, Payroll.DateStart, Payroll.DateEnd
	|";
	Env.Selection.Add ( str );	
	getData ();

	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	// Default values
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	
	// Period
	FieldsValues [ "Period" ] = DateStart;
	
	// *********
	// Table1
	// *********
	
	salaryAmount = Env.Salary.Amount;
	FieldsValues [ "A32" ] = ? ( salaryAmount = null, 0 , salaryAmount );
	taxes = Env.Taxes;
	medical = taxes.Medical;
	income = taxes.Income;
	FieldsValues [ "B32" ] = ? ( income = null, 0 , income );
	FieldsValues [ "C32" ] = ? ( medical = null, 0 , medical );
	
	for each row in Env.Table1 do
	    if ( row.Row = "Continue" ) then
	    	continue;
	    endif;
		FieldsValues [ "A" + row.Row ] = row.BaseAmount;
		FieldsValues [ "B" + row.Row ] = row.IncomeAmount;
	enddo;
	
	// *********
	// Table1 annex
	// *********
	
	line = 1;
	rowNumber = 87;
	for each row in Env.Attachment do
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = row.Division;
		amount = row.Amount;
		FieldsValues [ "D" + rowNumber ] = amount;
		FieldsValues [ "E" + rowNumber ] = amount;
		FieldsValues [ "F" + rowNumber ] = 0.00;
		rowNumber = rowNumber + 1;
		line = line + 1;
	enddo;

	// *********
	// Table3
	// *********
	
	line = 0;
	rowNumber = 191;
	pin = undefined;
	for each row in Env.Table3 do
		if ( pin <> row.PIN ) then
			line = line + 1;
			pin = row.PIN;
		endif;
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = Upper ( TrimAll ( row.LastName ) + " " + TrimAll ( row.FirstName ) );
		FieldsValues [ "C" + rowNumber ] = row.PIN;
		FieldsValues [ "D" + rowNumber ] = row.SIN;
		FieldsValues [ "E" + rowNumber ] = row.DateStart;
		FieldsValues [ "F" + rowNumber ] = row.DateEnd;
		FieldsValues [ "G" + rowNumber ] = row.Category;
		FieldsValues [ "M" + rowNumber ] = row.Rate;
		FieldsValues [ "H" + rowNumber ] = row.PositionCode;
		FieldsValues [ "I" + rowNumber ] = row.Salary;
		FieldsValues [ "J" + rowNumber ] = row.Disability;
		FieldsValues [ "K" + rowNumber ] = row.SocialInsurance;
		rowNumber = rowNumber + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	
	TabDoc.PageOrientation = PageOrientation.Landscape;	
	draw ();

EndProcedure

//****************
// Table 1
//****************

Procedure A51 ()

	result = sum ( "A32:A50" ) + sum ( "A52:A54" );

EndProcedure

Procedure B51 ()

	result = sum ( "B32:B35" ) + sum ( "B37:B50" ) + sum ( "B52:B54" );

EndProcedure

Procedure C51 ()

	result = sum ( "C32:C33" );

EndProcedure

Procedure CheckAmount ()

	result = get ( "B51" ) - sum ( "B37:B44" ) - sum ( "B52:53" );

EndProcedure

//****************
// Table 1 annex
//****************

Procedure D125 ()

	result = sum ( "D87:D124" );

EndProcedure

Procedure E125 ()

	result = sum ( "E87:E124" );

EndProcedure

Procedure F125 ()

	result = sum ( "F87:F124" );

EndProcedure

Procedure D87 ()

	result = sum ( "E87:F87" );

EndProcedure

Procedure D88 ()

	result = sum ( "E88:F88" );

EndProcedure


Procedure D89 ()

	result = sum ( "E89:F89" );

EndProcedure

Procedure D90 ()

	result = sum ( "E90:F90" );

EndProcedure

Procedure D91 ()

	result = sum ( "E91:F91" );

EndProcedure

Procedure D92 ()

	result = sum ( "E92:F92" );

EndProcedure

Procedure D93 ()

	result = sum ( "E93:F93" );

EndProcedure

Procedure D94 ()

	result = sum ( "E94:F94" );

EndProcedure

Procedure D95 ()

	result = sum ( "E95:F95" );

EndProcedure

Procedure D96 ()

	result = sum ( "E96:F96" );

EndProcedure

Procedure D97 ()

	result = sum ( "E97:F97" );

EndProcedure

Procedure D98 ()

	result = sum ( "E98:F98" );

EndProcedure

Procedure D99 ()

	result = sum ( "E99:F99" );

EndProcedure

Procedure D100 ()

	result = sum ( "E100:F100" );

EndProcedure

Procedure D101 ()

	result = sum ( "E101:F101" );

EndProcedure

Procedure D102 ()

	result = sum ( "E102:F102" );

EndProcedure

Procedure D103 ()

	result = sum ( "E103:F103" );

EndProcedure

Procedure D104 ()

	result = sum ( "E104:F104" );

EndProcedure

Procedure D105 ()

	result = sum ( "E105:F105" );

EndProcedure

Procedure D106 ()

	result = sum ( "E106:F106" );

EndProcedure

Procedure D107 ()

	result = sum ( "E107:F107" );

EndProcedure

Procedure D108 ()

	result = sum ( "E108:F108" );

EndProcedure

Procedure D109 ()

	result = sum ( "E109:F109" );

EndProcedure

Procedure D110 ()

	result = sum ( "E110:F110" );

EndProcedure

Procedure D111 ()

	result = sum ( "E111:F111" );

EndProcedure

Procedure D112 ()

	result = sum ( "E112:F112" );

EndProcedure

Procedure D113 ()

	result = sum ( "E113:F113" );

EndProcedure

Procedure D114 ()

	result = sum ( "E114:F114" );

EndProcedure

Procedure D115 ()

	result = sum ( "E115:F115" );

EndProcedure

Procedure D116 ()

	result = sum ( "E116:F116" );

EndProcedure

Procedure D117 ()

	result = sum ( "E117:F117" );

EndProcedure

Procedure D118 ()

	result = sum ( "E118:F118" );

EndProcedure

Procedure D119 ()

	result = sum ( "E119:F119" );

EndProcedure

Procedure D120 ()

	result = sum ( "E120:F120" );

EndProcedure

Procedure D121 ()

	result = sum ( "E121:F121" );

EndProcedure

Procedure D122 ()

	result = sum ( "E122:F122" );

EndProcedure

Procedure D123 ()

	result = sum ( "E123:F123" );

EndProcedure

Procedure D124 ()

	result = sum ( "E124:F124" );

EndProcedure

//****************
// Totals
//****************

Procedure I339 ()

	result = sum ( "I191:I338" );

EndProcedure

Procedure I341 ()

	result = get ( "I339" );

EndProcedure

Procedure J339 ()

	result = sum ( "J191:J338" );

EndProcedure

Procedure K339 ()

	result = sum ( "K191:K338" );

EndProcedure

Procedure K341 ()

	result = get ( "K339" );

EndProcedure
