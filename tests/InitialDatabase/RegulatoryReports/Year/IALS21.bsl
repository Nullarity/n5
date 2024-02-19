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
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account.Code = ""5343"", ,
	|		Company = &Company
	|		and ExtDimension1 <> value ( Enum.IncomeCodes.EmptyRef ), ,
	|		value ( ChartOfCharacteristicTypes.Dimensions.Organizations )
	|) as Turnovers
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
	|// PayEmployees
	|select Compensations.Amount as SalaryAmount, Compensations.Employee as Individual, Compensations.Ref as Recorder
	|into PayEmployees
	|from Document.PayEmployees.Compensations as Compensations
	|where Compensations.Ref.Date between &DateStart and &DateEnd
	|and Compensations.Ref.Company = &Company
	|and Compensations.Ref.Posted
	|and Compensations.Compensation in (
	|	select distinct CalculationType
	|	from ChartOfCalculationTypes.Taxes.BaseCalculationTypes
	|	where Ref.Method = value ( Enum.Calculations.IncomeTax )
	|)
	|;
	|// Salary
	|select sum ( isnull ( Salary.SalaryAmount, 0 ) ) as SalaryAmount, Salary.Individual as Individual, sum ( isnull ( Salary.MedicalAmount, 0 ) ) as MedicalAmount, 
	|	sum ( isnull ( Salary.IncomeTaxAmount, 0 ) ) as IncomeTaxAmount
	|into Salary
	|from (
	|	select PayEmployees.SalaryAmount as SalaryAmount, PayEmployees.Individual as Individual, 0 as MedicalAmount, 0 as IncomeTaxAmount 
	|	from PayEmployees as PayEmployees
	|	union all
	|	select 0, Compensations.Employee, Compensations.Medical, Compensations.IncomeTax
	|	from Document.PayEmployees.Totals as Compensations
	|	where Compensations.Ref.Date between &DateStart and &DateEnd
	|	and Compensations.Ref.Company = &Company
	|	and Compensations.Ref.Posted
	|	) as Salary
	|group by Salary.Individual
	|;
	|// #Employees
	|select Employees.LastName + "" "" + Employees.FirstName as Employee, Employees.Individual.PIN as PIN, ""SAL"" as Code, Salary.SalaryAmount as SalaryAmount, Salary.MedicalAmount as MedicalAmount,
	|	Salary.IncomeTaxAmount as IncomeTaxAmount, isnull ( PayEmployees.MonthsCount, 0 ) as MonthsCount,
	|	case when Statuses.FromInfobase then Statuses.Individual.PIN else Statuses.PIN end as SpousePIN, Employees.Individual as EmployeeRef,
	|	isnull ( Citizenship.Country.Code, ""MDA"" ) as CountryCode
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
	|		select Statuses.PIN as PIN, Statuses.Individual as Individual, Statuses.Select as FromInfobase
	|		from InformationRegister.MaritalStatuses.SliceLast ( &DateEnd, Individual in ( select Individual from Salary ) ) as Statuses
	|		) as Statuses
	|	on Statuses.Individual = Salary.Individual
	|	//
	|	// Citizenship
	|	//
	|	left join InformationRegister.Citizenship.SliceLast ( &DateEnd ) as Citizenship
	|	on Citizenship.Individual = Employees.Individual
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
	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "RecordsNumber" ] = Env.Employees.Count ();
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
	    FieldsValues [ "G" + i ] = row.CountryCode;
	    filter.Employee = row.EmployeeRef;
	    for each rowDeduction in deductions.FindRows ( filter ) do
	    	 FieldsValues [ rowDeduction.Deduction + i ] = rowDeduction.Amount;	
	    enddo;
		FieldsValues [ "P" + i ] = row.MedicalAmount;
	    FieldsValues [ "Q" + i ] = 0;
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

	result = get ( "I51" ) + get ( "J51" ) + get ( "L51" ) + get ( "M51" ) + get ( "N51" );

EndProcedure

Procedure O52 ()

	result = get ( "I52" ) + get ( "J52" ) + get ( "L52" ) + get ( "M52" ) + get ( "N52" );

EndProcedure

Procedure O53 ()

	result = get ( "I53" ) + get ( "J53" ) + get ( "L53" ) + get ( "M53" ) + get ( "N53" );

EndProcedure

Procedure O54 ()

	result = get ( "I54" ) + get ( "J54" ) + get ( "L54" ) + get ( "M54" ) + get ( "N54" );

EndProcedure

Procedure O55 ()

	result = get ( "I55" ) + get ( "J55" ) + get ( "L55" ) + get ( "M55" ) + get ( "N55" );

EndProcedure

Procedure O56 ()

	result = get ( "I56" ) + get ( "J56" ) + get ( "L56" ) + get ( "M56" ) + get ( "N56" );

EndProcedure

Procedure O57 ()

	result = get ( "I57" ) + get ( "J57" ) + get ( "L57" ) + get ( "M57" ) + get ( "N57" );

EndProcedure

Procedure O58 ()

	result = get ( "I58" ) + get ( "J58" ) + get ( "L58" ) + get ( "M58" ) + get ( "N58" );

EndProcedure

Procedure O59 ()

	result = get ( "I59" ) + get ( "J59" ) + get ( "L59" ) + get ( "M59" ) + get ( "N59" );

EndProcedure

Procedure O60 ()

	result = get ( "I60" ) + get ( "J60" ) + get ( "L60" ) + get ( "M60" ) + get ( "N60" );

EndProcedure

Procedure O61 ()

	result = get ( "I61" ) + get ( "J61" ) + get ( "L61" ) + get ( "M61" ) + get ( "N61" );

EndProcedure

Procedure O62 ()

	result = get ( "I62" ) + get ( "J62" ) + get ( "L62" ) + get ( "M62" ) + get ( "N62" );

EndProcedure

Procedure O63 ()

	result = get ( "I63" ) + get ( "J63" ) + get ( "L63" ) + get ( "M63" ) + get ( "N63" );

EndProcedure

Procedure O64 ()

	result = get ( "I64" ) + get ( "J64" ) + get ( "L64" ) + get ( "M64" ) + get ( "N64" );

EndProcedure

Procedure O65 ()

	result = get ( "I65" ) + get ( "J65" ) + get ( "L65" ) + get ( "M65" ) + get ( "N65" );

EndProcedure

Procedure O66 ()

	result = get ( "I66" ) + get ( "J66" ) + get ( "L66" ) + get ( "M66" ) + get ( "N66" );

EndProcedure

Procedure O67 ()

	result = get ( "I67" ) + get ( "J67" ) + get ( "L67" ) + get ( "M67" ) + get ( "N67" );

EndProcedure

Procedure O68 ()

	result = get ( "I68" ) + get ( "J68" ) + get ( "L68" ) + get ( "M68" ) + get ( "N68" );

EndProcedure

Procedure O69 ()

	result = get ( "I69" ) + get ( "J69" ) + get ( "L69" ) + get ( "M69" ) + get ( "N69" );

EndProcedure

Procedure O70 ()

	result = get ( "I70" ) + get ( "J70" ) + get ( "L70" ) + get ( "M70" ) + get ( "N70" );

EndProcedure

Procedure O71 ()

	result = get ( "I71" ) + get ( "J71" ) + get ( "L71" ) + get ( "M71" ) + get ( "N71" );

EndProcedure

Procedure O72 ()

	result = get ( "I72" ) + get ( "J72" ) + get ( "L72" ) + get ( "M72" ) + get ( "N72" );

EndProcedure

Procedure O73 ()

	result = get ( "I73" ) + get ( "J73" ) + get ( "L73" ) + get ( "M73" ) + get ( "N73" );

EndProcedure

Procedure O74 ()

	result = get ( "I74" ) + get ( "J74" ) + get ( "L74" ) + get ( "M74" ) + get ( "N74" );

EndProcedure

Procedure O75 ()

	result = get ( "I75" ) + get ( "J75" ) + get ( "L75" ) + get ( "M75" ) + get ( "N75" );

EndProcedure

Procedure O76 ()

	result = get ( "I76" ) + get ( "J76" ) + get ( "L76" ) + get ( "M76" ) + get ( "N76" );

EndProcedure

Procedure O77 ()

	result = get ( "I77" ) + get ( "J77" ) + get ( "L77" ) + get ( "M77" ) + get ( "N77" );

EndProcedure

Procedure O78 ()

	result = get ( "I78" ) + get ( "J78" ) + get ( "L78" ) + get ( "M78" ) + get ( "N78" );

EndProcedure

Procedure O79 ()

	result = get ( "I79" ) + get ( "J79" ) + get ( "L79" ) + get ( "M79" ) + get ( "N79" );

EndProcedure

Procedure O80 ()
	
	result = get ( "I80" ) + get ( "J80" ) + get ( "L80" ) + get ( "M80" ) + get ( "N80" );
	
EndProcedure

Procedure O81 ()

	result = get ( "I81" ) + get ( "J81" ) + get ( "L81" ) + get ( "M81" ) + get ( "N81" );

EndProcedure

Procedure O82 ()

	result = get ( "I82" ) + get ( "J82" ) + get ( "L82" ) + get ( "M82" ) + get ( "N82" );

EndProcedure

Procedure O83 ()

	result = get ( "I83" ) + get ( "J83" ) + get ( "L83" ) + get ( "M83" ) + get ( "N83" );

EndProcedure

Procedure O84 ()

	result = get ( "I84" ) + get ( "J84" ) + get ( "L84" ) + get ( "M84" ) + get ( "N84" );

EndProcedure

Procedure O85 ()

	result = get ( "I85" ) + get ( "J85" ) + get ( "L85" ) + get ( "M85" ) + get ( "N85" );

EndProcedure

Procedure O86 ()

	result = get ( "I86" ) + get ( "J86" ) + get ( "L86" ) + get ( "M86" ) + get ( "N86" );

EndProcedure

Procedure O87 ()

	result = get ( "I87" ) + get ( "J87" ) + get ( "L87" ) + get ( "M87" ) + get ( "N87" );

EndProcedure

Procedure O88 ()

	result = get ( "I88" ) + get ( "J88" ) + get ( "L88" ) + get ( "M88" ) + get ( "N88" );

EndProcedure

Procedure O89 ()

	result = get ( "I89" ) + get ( "J89" ) + get ( "L89" ) + get ( "M89" ) + get ( "N89" );

EndProcedure

Procedure O90 ()

	result = get ( "I90" ) + get ( "J90" ) + get ( "L90" ) + get ( "M90" ) + get ( "N90" );

EndProcedure

Procedure O91 ()

	result = get ( "I91" ) + get ( "J91" ) + get ( "L91" ) + get ( "M91" ) + get ( "N91" );

EndProcedure

Procedure O92 ()

	result = get ( "I92" ) + get ( "J92" ) + get ( "L92" ) + get ( "M92" ) + get ( "N92" );

EndProcedure

Procedure O93 ()

	result = get ( "I93" ) + get ( "J93" ) + get ( "L93" ) + get ( "M93" ) + get ( "N93" );

EndProcedure

Procedure O94 ()

	result = get ( "I94" ) + get ( "J94" ) + get ( "L94" ) + get ( "M94" ) + get ( "N94" );

EndProcedure

Procedure O95 ()

	result = get ( "I95" ) + get ( "J95" ) + get ( "L95" ) + get ( "M95" ) + get ( "N95" );

EndProcedure

Procedure O96 ()

	result = get ( "I96" ) + get ( "J96" ) + get ( "L96" ) + get ( "M96" ) + get ( "N96" );

EndProcedure

Procedure O97 ()

	result = get ( "I97" ) + get ( "J97" ) + get ( "L97" ) + get ( "M97" ) + get ( "N97" );

EndProcedure

Procedure O98 ()

	result = get ( "I98" ) + get ( "J98" ) + get ( "L98" ) + get ( "M98" ) + get ( "N98" );

EndProcedure

Procedure O99 ()

	result = get ( "I99" ) + get ( "J99" ) + get ( "L99" ) + get ( "M99" ) + get ( "N99" );

EndProcedure

Procedure O100 ()

	result = get ( "I100" ) + get ( "J100" ) + get ( "L100" ) + get ( "M100" ) + get ( "N100" );

EndProcedure

Procedure O101 ()

	result = get ( "I101" ) + get ( "J101" ) + get ( "L101" ) + get ( "M101" ) + get ( "N101" );

EndProcedure

Procedure O102 ()

	result = get ( "I102" ) + get ( "J102" ) + get ( "L102" ) + get ( "M102" ) + get ( "N102" );

EndProcedure

Procedure O103 ()

	result = get ( "I103" ) + get ( "J103" ) + get ( "L103" ) + get ( "M103" ) + get ( "N103" );

EndProcedure

Procedure O104 ()

	result = get ( "I104" ) + get ( "J104" ) + get ( "L104" ) + get ( "M104" ) + get ( "N104" );

EndProcedure

Procedure O105 ()

	result = get ( "I105" ) + get ( "J105" ) + get ( "L105" ) + get ( "M105" ) + get ( "N105" );

EndProcedure

Procedure O106 ()

	result = get ( "I106" ) + get ( "J106" ) + get ( "L106" ) + get ( "M106" ) + get ( "N106" );

EndProcedure

Procedure O107 ()

	result = get ( "I107" ) + get ( "J107" ) + get ( "L107" ) + get ( "M107" ) + get ( "N107" );

EndProcedure

Procedure O108 ()

	result = get ( "I108" ) + get ( "J108" ) + get ( "L108" ) + get ( "M108" ) + get ( "N108" );

EndProcedure

Procedure O109 ()

	result = get ( "I109" ) + get ( "J109" ) + get ( "L109" ) + get ( "M109" ) + get ( "N109" );

EndProcedure

Procedure O110 ()

	result = get ( "I110" ) + get ( "J110" ) + get ( "L110" ) + get ( "M110" ) + get ( "N110" );

EndProcedure

Procedure O111 ()

	result = get ( "I111" ) + get ( "J111" ) + get ( "L111" ) + get ( "M111" ) + get ( "N111" );

EndProcedure

Procedure O112 ()

	result = get ( "I112" ) + get ( "J112" ) + get ( "L112" ) + get ( "M112" ) + get ( "N112" );

EndProcedure

Procedure O113 ()

	result = get ( "I113" ) + get ( "J113" ) + get ( "L113" ) + get ( "M113" ) + get ( "N113" );

EndProcedure

Procedure O114 ()

	result = get ( "I114" ) + get ( "J114" ) + get ( "L114" ) + get ( "M114" ) + get ( "N114" );

EndProcedure

Procedure O115 ()

	result = get ( "I115" ) + get ( "J115" ) + get ( "L115" ) + get ( "M115" ) + get ( "N115" );

EndProcedure

Procedure O116 ()

	result = get ( "I116" ) + get ( "J116" ) + get ( "L116" ) + get ( "M116" ) + get ( "N116" );

EndProcedure

Procedure O117 ()

	result = get ( "I117" ) + get ( "J117" ) + get ( "L117" ) + get ( "M117" ) + get ( "N117" );

EndProcedure

Procedure O118 ()

	result = get ( "I118" ) + get ( "J118" ) + get ( "L118" ) + get ( "M118" ) + get ( "N118" );

EndProcedure

Procedure O119 ()

	result = get ( "I119" ) + get ( "J119" ) + get ( "L119" ) + get ( "M119" ) + get ( "N119" );

EndProcedure

Procedure O120 ()

	result = get ( "I120" ) + get ( "J120" ) + get ( "L120" ) + get ( "M120" ) + get ( "N120" );

EndProcedure

Procedure O121 ()

	result = get ( "I121" ) + get ( "J121" ) + get ( "L121" ) + get ( "M121" ) + get ( "N121" );

EndProcedure

Procedure O122 ()

	result = get ( "I122" ) + get ( "J122" ) + get ( "L122" ) + get ( "M122" ) + get ( "N122" );

EndProcedure

Procedure O123 ()

	result = get ( "I123" ) + get ( "J123" ) + get ( "L123" ) + get ( "M123" ) + get ( "N123" );

EndProcedure

Procedure O124 ()

	result = get ( "I124" ) + get ( "J124" ) + get ( "L124" ) + get ( "M124" ) + get ( "N124" );

EndProcedure

Procedure O125 ()

	result = get ( "I125" ) + get ( "J125" ) + get ( "L125" ) + get ( "M125" ) + get ( "N125" );

EndProcedure

Procedure O126 ()

	result = get ( "I126" ) + get ( "J126" ) + get ( "L126" ) + get ( "M126" ) + get ( "N126" );

EndProcedure

Procedure O127 ()

	result = get ( "I127" ) + get ( "J127" ) + get ( "L127" ) + get ( "M127" ) + get ( "N127" );

EndProcedure

Procedure O128 ()

	result = get ( "I128" ) + get ( "J128" ) + get ( "L128" ) + get ( "M128" ) + get ( "N128" );

EndProcedure

Procedure O129 ()

	result = get ( "I129" ) + get ( "J129" ) + get ( "L129" ) + get ( "M129" ) + get ( "N129" );

EndProcedure

Procedure O130 ()

	result = get ( "I130" ) + get ( "J130" ) + get ( "L130" ) + get ( "M130" ) + get ( "N130" );

EndProcedure

Procedure O131 ()

	result = get ( "I131" ) + get ( "J131" ) + get ( "L131" ) + get ( "M131" ) + get ( "N131" );

EndProcedure

Procedure O132 ()

	result = get ( "I132" ) + get ( "J132" ) + get ( "L132" ) + get ( "M132" ) + get ( "N132" );

EndProcedure

Procedure O133 ()

	result = get ( "I133" ) + get ( "J133" ) + get ( "L133" ) + get ( "M133" ) + get ( "N133" );

EndProcedure

Procedure O134 ()

	result = get ( "I134" ) + get ( "J134" ) + get ( "L134" ) + get ( "M134" ) + get ( "N134" );

EndProcedure

Procedure O135 ()

	result = get ( "I135" ) + get ( "J135" ) + get ( "L135" ) + get ( "M135" ) + get ( "N135" );

EndProcedure

Procedure O136 ()

	result = get ( "I136" ) + get ( "J136" ) + get ( "L136" ) + get ( "M136" ) + get ( "N136" );

EndProcedure

Procedure O137 ()

	result = get ( "I137" ) + get ( "J137" ) + get ( "L137" ) + get ( "M137" ) + get ( "N137" );

EndProcedure

Procedure O138 ()

	result = get ( "I138" ) + get ( "J138" ) + get ( "L138" ) + get ( "M138" ) + get ( "N138" );

EndProcedure

Procedure O139 ()

	result = get ( "I139" ) + get ( "J139" ) + get ( "L139" ) + get ( "M139" ) + get ( "N139" );

EndProcedure

Procedure O140 ()

	result = get ( "I140" ) + get ( "J140" ) + get ( "L140" ) + get ( "M140" ) + get ( "N140" );

EndProcedure

Procedure O141 ()

	result = sum ( "O51:O140" );

EndProcedure

Procedure F141 ()

	result = sum ( "F51:F140" );

EndProcedure
Procedure I141 ()

	result = sum ( "I51:I140" );

EndProcedure

Procedure J141 ()

	result = sum ( "J51:J140" );

EndProcedure

Procedure K141 ()

	result = sum ( "K51:K140" );

EndProcedure

Procedure L141 ()

	result = sum ( "L51:L140" );

EndProcedure

Procedure M141 ()

	result = sum ( "M51:M140" );

EndProcedure

Procedure N141 ()

	result = sum ( "N51:N140" );

EndProcedure

Procedure P141 ()

	result = sum ( "P51:P140" );

EndProcedure

Procedure Q141 ()

	result = sum ( "Q51:Q140" );

EndProcedure

Procedure R141 ()

	result = sum ( "R51:R140" );

EndProcedure