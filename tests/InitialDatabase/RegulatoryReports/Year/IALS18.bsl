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
	|// Income
	|select sum ( Turnovers.AmountTurnoverCr ) as Amount, Turnovers.BalancedAccount as Account, Turnovers.ExtDimension1 as Code, Turnovers.Recorder as Recorder,
	|	Turnovers.BalancedExtDimension1 as Organization
	|into Income
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account.Code = ""5343"", 
	|, Company = &Company
	|		and ExtDimension1 <> value ( Enum.IncomeCodes.EmptyRef ), , value ( ChartOfCharacteristicTypes.Dimensions.Organizations ) ) as Turnovers
	|group by Turnovers.BalancedAccount, Turnovers.ExtDimension1, Turnovers.Recorder, Turnovers.BalancedExtDimension1
	|;
	|// Base
	|select sum ( Turnovers.AmountTurnoverDr ) as Amount, Income.Code as Code, Turnovers.ExtDimension1 as Organization
	|into Base
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account in ( select Account from Income ), , Company = &Company
	|		and ExtDimension1 in ( select Organization from Income ), ,  ) as Turnovers
	|	// 
	|	// Income
	|	// 
	|	left join Income as Income
	|	on Income.Recorder = Turnovers.Recorder
	|	and Income.Organization = Turnovers.ExtDimension1
	|where Turnovers.Recorder in ( select Recorder from Income )
	|group by Income.Code, Turnovers.ExtDimension1 
	|;
	|// #Organizations
	|select isnull ( Income.Amount, 0 ) as IncomeTaxAmount, presentation ( Income.Code ) as Code, isnull ( Base.Amount, 0 ) as BaseAmount, Income.Organization.CodeFiscal as CodeFiscal,
	|	Income.Organization.Description as Organization
	|from ( select sum ( Income.Amount ) as Amount, Income.Code as Code, Income.Organization as Organization
	|		from Income as Income
	|		group by Income.Code, Income.Organization
	|	  ) as Income
	|	// 
	|	// Base
	|	// 
	|	left join Base as Base
	|	on Base.Code = Income.Code
	|	and Base.Organization = Income.Organization
	|	// 
	|	// Deductions
	|	// 
	|	left join InformationRegister.DeductionRates.SliceLast ( &DateEnd, Deduction.Code = ""P"" ) as Rates
	|	on true
	|where case when Income.Code in ( value ( Enum.IncomeCodes.FOL ), value ( Enum.IncomeCodes.DIVA ), value ( Enum.IncomeCodes.RCSA ), value ( Enum.IncomeCodes.ROY ), 
	|			value ( Enum.IncomeCodes.NOR ), value ( Enum.IncomeCodes.PUB ), value ( Enum.IncomeCodes.LIV ) )
	|			then case when isnull ( Base.Amount, 0 ) >= isnull ( Rates.Rate, 0)	then true
	|					else false
	|				end
	|			else true
	|		end
	|order by Income.Organization.Description
	|;
	|// Compensations
	|select Compensations.Account as Account, Compensations.Ref as Salary
	|into Compensations
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where Compensations.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) )
	|and not Compensations.DeletionMark
	|;
	|// PayEmployees
	|select Turnovers.AmountTurnoverDr as SalaryAmount, ExtDimension1 as Individual, Turnovers.Recorder as Recorder
	|into PayEmployees
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account in ( select Account from Compensations ), , Company = &Company
	|						and ExtDimension2 in ( select Salary from Compensations ), ) as Turnovers
	|;
	|// Salary
	|select sum ( isnull ( Salary.SalaryAmount, 0 ) ) as SalaryAmount, Salary.Individual as Individual, sum ( isnull ( Salary.MedicalAmount, 0 ) ) as MedicalAmount, 
	|	sum ( isnull ( Salary.SocialAmount, 0 ) ) as SocialAmount, sum ( isnull ( Salary.IncomeTaxAmount, 0 ) ) as IncomeTaxAmount
	|into Salary
	|from (
	|	select PayEmployees.SalaryAmount as SalaryAmount, PayEmployees.Individual as Individual, 0 as MedicalAmount, 0 as SocialAmount, 0 as IncomeTaxAmount 
	|	from PayEmployees as PayEmployees
	|	union all
	|	select 0, BalancedExtDimension1, Turnovers.AmountTurnoverCr, 0, 0
	|	from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , 
	|		Account in ( 
	|			select Taxes.Account as Account
	|			from ChartOfCalculationTypes.Taxes as Taxes
	|			where Taxes.Method = value ( Enum.Calculations.MedicalInsuranceEmployee )
	|			and not Taxes.DeletionMark 
	|					), , 
	|		Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|	union all
	|	select 0, BalancedExtDimension1, 0, Turnovers.AmountTurnoverCr, 0
	|	from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account = &EmployeesOtherDebt, , Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|	union all
	|	select 0, BalancedExtDimension1, 0, 0, Turnovers.AmountTurnoverCr
	|	from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , 
	|		Account in ( 
	|			select Taxes.Account as Account
	|			from ChartOfCalculationTypes.Taxes as Taxes
	|			where Taxes.Method = value ( Enum.Calculations.IncomeTax ) or Taxes.Method = value ( Enum.Calculations.FixedIncomeTax )
	|			and not Taxes.DeletionMark 
	|					), , 
	|		Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|	) as Salary
	|group by Salary.Individual
	|;
	|// #Employees
	|select Employees.Description as Employee, Employees.Individual.PIN as PIN, ""SAL"" as Code, Salary.SalaryAmount as SalaryAmount, Salary.MedicalAmount as MedicalAmount,
	|	Salary.SocialAmount as SocialAmount, Salary.IncomeTaxAmount as IncomeTaxAmount, isnull ( PayEmployees.MonthsCount, 0 ) as MonthsCount, Statuses.PIN as SpousePIN, Employees.Individual as EmployeeRef
	|from Salary as Salary
	|	// 
	|	// Employees
	|	// 
	|	left join Catalog.Employees as Employees
	|	on Employees.Individual = Salary.Individual
	|	// 
	|	// Compensations
	|	// 
	|	left join (
	|		select count ( distinct beginofperiod ( PayEmployees.Recorder.Date, month ) ) as MonthsCount, PayEmployees.Individual as Individual
	|		from PayEmployees as PayEmployees
	|		group by PayEmployees.Individual
	|			  ) as PayEmployees
	|	on PayEmployees.Individual = Salary.Individual
	|	//
	|	// Statuses
	|	//
	|	left join ( 
	|		select Statuses.PIN as PIN, Statuses.Individual as Individual
	|		from InformationRegister.MaritalStatuses.SliceLast ( &DateEnd, Individual in ( select Individual from Salary ) ) as Statuses
	|		) as Statuses
	|	on Statuses.Individual = Salary.Individual
	|order by Employees.Description
	|;
	|// Employees
	|select Salary.Individual as Employee
	|into Employees
	|from Salary as Salary 
	|;
	|// Calendar
	|select Period as Period
	|into Calendar
	|from (
	|    select &DateStart as Period
	|    union all
	|    select dateadd ( &DateStart, month, 1 )
	|    union all
	|    select dateadd ( &DateStart, month, 2 )
	|    union all
	|    select dateadd ( &DateStart, month, 3 )
	|    union all
	|    select dateadd ( &DateStart, month, 4 )
	|    union all
	|    select dateadd ( &DateStart, month, 5 )
	|    union all
	|    select dateadd ( &DateStart, month, 6 )
	|    union all
	|    select dateadd ( &DateStart, month, 7 )
	|    union all
	|    select dateadd ( &DateStart, month, 8 )
	|    union all
	|    select dateadd ( &DateStart, month, 9 )
	|    union all
	|    select dateadd ( &DateStart, month, 10 )
	|    union all
	|    select dateadd ( &DateStart, month, 11 )
	|    ) as Calendar
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
	|    //
	|    // DeductionPeriods
	|    //
	|    join (
	|        select Calendar.Period as Period, Deductions.Deduction as Deduction, max ( Deductions.Period ) as DeductionPeriod
	|        from Calendar as Calendar
	|            //
	|            // Deductions
	|            //
	|            left join DeductionRates as Deductions
	|            on Deductions.Period <= Calendar.Period
	|        group by Calendar.Period, Deductions.Deduction
	|    ) as DeductionPeriods
	|    on DeductionPeriods.Period = Calendar.Period
	|    //
	|    // DeductionRate
	|    //
	|    join DeductionRates as Deductions
	|    on Deductions.Deduction = DeductionPeriods.Deduction
	|    and Deductions.Period = DeductionPeriods.DeductionPeriod
	|index by Period, Deduction
	|;
	|// EmployeeDeductions
	|select &DateStart as Period, true as Use, Deductions.Employee.Individual as Employee, Deductions.Deduction as Deduction
	|into EmployeeDeductions
	|from InformationRegister.Deductions.SliceLast ( &DateStart, Employee.Individual in ( select Employee from Employees ) ) as Deductions
	|where Deductions.Use
	|union all
	|select Deductions.Period, Deductions.Use, Deductions.Employee.Individual, Deductions.Deduction
	|from InformationRegister.Deductions as Deductions
	|where Employee.Individual in ( select Employee from Employees )
	|and Deductions.Period > &DateStart and Deductions.Period <= &DateEnd
	|index by Period, Employee
	|;
	|// EmployeeDeductionPeriods
	|select Calendar.Period as Period, Deductions.Employee as Employee, Deductions.Deduction as Deduction,
	|    max ( Deductions.Period ) as DeductionPeriod
	|into EmployeeDeductionPeriods
	|from Calendar as Calendar
	|    //
	|    // Deductions
	|    //
	|    left join EmployeeDeductions as Deductions
	|    on Deductions.Period <= Calendar.Period
	|group by Calendar.Period, Deductions.Employee, Deductions.Deduction
	|index by Period, Employee
	|;
	|// #Deductions
	|select Deductions.Employee as Employee, sum ( case when Deductions.Use then DeductionsList.Rate / 12 else 0 end ) as Amount,
	|	case when Deductions.Deduction.Code = ""P"" then ""I""
	|		when Deductions.Deduction.Code = ""M"" then ""J""
	|		when Deductions.Deduction.Code = ""S"" then ""K""
	|		when Deductions.Deduction.Code = ""Sm"" then ""L""
	|		when Deductions.Deduction.Code = ""N"" then ""M""
	|		else ""N""
	|	end as Deduction
	|from Calendar as Calendar
	|    //
	|    // DeductionPeriods
	|    //
	|    join EmployeeDeductionPeriods as DeductionPeriods
	|    on DeductionPeriods.Period = Calendar.Period
	|    //
	|    // Deductions
	|    //
	|    join EmployeeDeductions as Deductions
	|    on Deductions.Period = DeductionPeriods.DeductionPeriod
	|    and Deductions.Employee = DeductionPeriods.Employee
	|    and Deductions.Deduction = DeductionPeriods.Deduction
	|    //
	|    // DeductionsList
	|    //
	|    join DeductionsList as DeductionsList
	|    on DeductionsList.Period = Calendar.Period
	|    and DeductionsList.Deduction = Deductions.Deduction
	|group by Deductions.Deduction, Deductions.Employee
	|;
	|";
	Env.Selection.Add ( str );	
	
	Env.Q.SetParameter ( "EmployeesOtherDebt", InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.EmployeesOtherDebt ) ).Value );
	
	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "Period" ] = "A/" + Format ( DateEnd, "DF='yyyy'" );
	
	// DefaultValues
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	
	//Fill table
	line = 1;
	i = 51;
	deductions = Env.Deductions;
	filter = new Structure ( "Employee" );
	for each row in Env.Employees do
	    FieldsValues [ "A" + i ] = line;
	    FieldsValues [ "B" + i ] = row.PIN;
	    FieldsValues [ "C" + i ] = row.Employee;
	    FieldsValues [ "D" + i ] = row.SpousePIN;
	    FieldsValues [ "E" + i ] = row.Code;
	    FieldsValues [ "F" + i ] = row.SalaryAmount;
	    FieldsValues [ "G" + i ] = row.MonthsCount;
	    
	    filter.Employee = row.EmployeeRef;
	    for each rowDeduction in deductions.FindRows ( filter ) do
	    	 FieldsValues [ rowDeduction.Deduction + i ] = rowDeduction.Amount;	
	    enddo;
	    	    FieldsValues [ "P" + i ] = row.MedicalAmount;
	    FieldsValues [ "Q" + i ] = row.SocialAmount;
	    FieldsValues [ "R" + i ] = row.IncomeTaxAmount;
		line = line + 1;
		i = i + 1;
	enddo;
	for each row in Env.Organizations do
	    FieldsValues [ "A" + i ] = line;
	    FieldsValues [ "B" + i ] = row.CodeFiscal;
	    FieldsValues [ "C" + i ] = row.Organization;
	    FieldsValues [ "E" + i ] = row.Code;
	    FieldsValues [ "F" + i ] = row.BaseAmount;
	    FieldsValues [ "R" + i ] = row.IncomeTaxAmount;
		line = line + 1;
		i = i + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   	endif;

EndProcedure

Procedure O51 ()

	result = get ( "I51" ) + get ( "J51" ) + get ( "K51" ) + get ( "L51" ) + get ( "M51" ) + get ( "N51" );

EndProcedure

Procedure O52 ()

	result = get ( "I52" ) + get ( "J52" ) + get ( "K52" ) + get ( "L52" ) + get ( "M52" ) + get ( "N52" );

EndProcedure

Procedure O53 ()

	result = get ( "I53" ) + get ( "J53" ) + get ( "K53" ) + get ( "L53" ) + get ( "M53" ) + get ( "N53" );

EndProcedure

Procedure O54 ()

	result = get ( "I54" ) + get ( "J54" ) + get ( "K54" ) + get ( "L54" ) + get ( "M54" ) + get ( "N54" );

EndProcedure

Procedure O55 ()

	result = get ( "I55" ) + get ( "J55" ) + get ( "K55" ) + get ( "L55" ) + get ( "M55" ) + get ( "N55" );

EndProcedure

Procedure O56 ()

	result = get ( "I56" ) + get ( "J56" ) + get ( "K56" ) + get ( "L56" ) + get ( "M56" ) + get ( "N56" );

EndProcedure

Procedure O57 ()

	result = get ( "I57" ) + get ( "J57" ) + get ( "K57" ) + get ( "L57" ) + get ( "M57" ) + get ( "N57" );

EndProcedure

Procedure O58 ()

	result = get ( "I58" ) + get ( "J58" ) + get ( "K58" ) + get ( "L58" ) + get ( "M58" ) + get ( "N58" );

EndProcedure

Procedure O59 ()

	result = get ( "I59" ) + get ( "J59" ) + get ( "K59" ) + get ( "L59" ) + get ( "M59" ) + get ( "N59" );

EndProcedure

Procedure O60 ()

	result = get ( "I60" ) + get ( "J60" ) + get ( "K60" ) + get ( "L60" ) + get ( "M60" ) + get ( "N60" );

EndProcedure

Procedure O61 ()

	result = get ( "I61" ) + get ( "J61" ) + get ( "K61" ) + get ( "L61" ) + get ( "M61" ) + get ( "N61" );

EndProcedure

Procedure O62 ()

	result = get ( "I62" ) + get ( "J62" ) + get ( "K62" ) + get ( "L62" ) + get ( "M62" ) + get ( "N62" );

EndProcedure

Procedure O63 ()

	result = get ( "I63" ) + get ( "J63" ) + get ( "K63" ) + get ( "L63" ) + get ( "M63" ) + get ( "N63" );

EndProcedure

Procedure O64 ()

	result = get ( "I64" ) + get ( "J64" ) + get ( "K64" ) + get ( "L64" ) + get ( "M64" ) + get ( "N64" );

EndProcedure

Procedure O65 ()

	result = get ( "I65" ) + get ( "J65" ) + get ( "K65" ) + get ( "L65" ) + get ( "M65" ) + get ( "N65" );

EndProcedure

Procedure O66 ()

	result = get ( "I66" ) + get ( "J66" ) + get ( "K66" ) + get ( "L66" ) + get ( "M66" ) + get ( "N66" );

EndProcedure

Procedure O67 ()

	result = get ( "I67" ) + get ( "J67" ) + get ( "K67" ) + get ( "L67" ) + get ( "M67" ) + get ( "N67" );

EndProcedure

Procedure O68 ()

	result = get ( "I68" ) + get ( "J68" ) + get ( "K68" ) + get ( "L68" ) + get ( "M68" ) + get ( "N68" );

EndProcedure

Procedure O69 ()

	result = get ( "I69" ) + get ( "J69" ) + get ( "K69" ) + get ( "L69" ) + get ( "M69" ) + get ( "N69" );

EndProcedure

Procedure O70 ()

	result = get ( "I70" ) + get ( "J70" ) + get ( "K70" ) + get ( "L70" ) + get ( "M70" ) + get ( "N70" );

EndProcedure

Procedure O71 ()

	result = get ( "I71" ) + get ( "J71" ) + get ( "K71" ) + get ( "L71" ) + get ( "M71" ) + get ( "N71" );

EndProcedure

Procedure O72 ()

	result = get ( "I72" ) + get ( "J72" ) + get ( "K72" ) + get ( "L72" ) + get ( "M72" ) + get ( "N72" );

EndProcedure

Procedure O73 ()

	result = get ( "I73" ) + get ( "J73" ) + get ( "K73" ) + get ( "L73" ) + get ( "M73" ) + get ( "N73" );

EndProcedure

Procedure O74 ()

	result = get ( "I74" ) + get ( "J74" ) + get ( "K74" ) + get ( "L74" ) + get ( "M74" ) + get ( "N74" );

EndProcedure

Procedure O75 ()

	result = get ( "I75" ) + get ( "J75" ) + get ( "K75" ) + get ( "L75" ) + get ( "M75" ) + get ( "N75" );

EndProcedure

Procedure O76 ()

	result = get ( "I76" ) + get ( "J76" ) + get ( "K76" ) + get ( "L76" ) + get ( "M76" ) + get ( "N76" );

EndProcedure

Procedure O77 ()

	result = get ( "I77" ) + get ( "J77" ) + get ( "K77" ) + get ( "L77" ) + get ( "M77" ) + get ( "N77" );

EndProcedure

Procedure O78 ()

	result = get ( "I78" ) + get ( "J78" ) + get ( "K78" ) + get ( "L78" ) + get ( "M78" ) + get ( "N78" );

EndProcedure

Procedure O79 ()

	result = get ( "I79" ) + get ( "J79" ) + get ( "K79" ) + get ( "L79" ) + get ( "M79" ) + get ( "N79" );

EndProcedure

Procedure O80 ()

	result = get ( "I80" ) + get ( "J80" ) + get ( "K80" ) + get ( "L80" ) + get ( "M80" ) + get ( "N80" );

EndProcedure

Procedure F81 ()

	result = sum ( "F51:F80" );

EndProcedure

Procedure G81 ()

	result = sum ( "G51:G80" );

EndProcedure

Procedure I81 ()

	result = sum ( "I51:I80" );

EndProcedure

Procedure J81 ()

	result = sum ( "J51:J80" );

EndProcedure

Procedure K81 ()

	result = sum ( "K51:K80" );

EndProcedure

Procedure L81 ()

	result = sum ( "L51:L80" );

EndProcedure

Procedure M81 ()

	result = sum ( "M51:M80" );

EndProcedure

Procedure N81 ()

	result = sum ( "N51:N80" );

EndProcedure

Procedure O81 ()

	result = sum ( "O51:O80" );

EndProcedure

Procedure P81 ()

	result = sum ( "P51:P80" );

EndProcedure

Procedure Q81 ()

	result = sum ( "Q51:Q80" );

EndProcedure

Procedure R81 ()

	result = sum ( "R51:R80" );

EndProcedure