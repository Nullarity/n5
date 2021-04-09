Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;

	str = "
	|// Employee
	|select Employees.Ref as Employee, Employees.Individual as Individual
	|into Employees
	|from Catalog.Employees as Employees
	|where  ( Employees.Individual.Description = &Employee or Employees.Individual.Code = &EmployeeCode )
	|;
	|// Personnel
	|select top 1 Personnel.Position as Post, Personnel.Schedule as Schedule
	|into Personnel
	|from InformationRegister.Personnel as Personnel
	|where Personnel.Employee in ( select Employee from Employees )
	|;
	|// @Fields
	|select Individuals.FirstName as FirstName, Individuals.LastName as LastName, Individuals.Patronymic as Patronymic,
	|	Individuals.SIN as SIN, Individuals.PIN as PIN, Company.FullDescription as Company, Company.CodeFiscal as CodeFiscal, year ( &DateEnd ) as PeriodYear,
	|	day ( ID.Issued ) as IssuedDay, month ( ID.Issued ) as IssuedMonth, ID.IssuedBy as IssuedBy, ID.Number as Number, ID.Series as Series, 
	|	year ( ID.Issued ) as IssuedYear, case when ID.Type = value ( Catalog.IDTypes.IdentityCard ) then true else false end as IdentityCard,
	|	Accountant.Name as Accountant, Director.Name as Director
	|from Catalog.Individuals as Individuals
	|	//
	|	// Employees
	|	//
	|	join Employees as Employees
	|	on true
	|	//
	|	// ID
	|	//
	|	left join ( 
	|		select top 1 ID.Issued as Issued, ID.IssuedBy as IssuedBy, ID.Number as Number, ID.Series as Series, ID.Type as Type
	|		from InformationRegister.ID.SliceLast ( &DateEnd, Individual in ( select Individual from Employees )
	|								 and Type in ( value ( Catalog.IDTypes.OldPassport ), value ( Catalog.IDTypes.IdentityCard ), value ( Catalog.IDTypes.MAI ) ) ) as ID
	|		) as ID
	|	on true
	|	//
	|	// Company
	|	//
	|	left join Catalog.Companies as Company
	|	on Company.Ref = &Company
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.HomePhone as HomePhone
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|		) as Accountant
	|	on true
	|	//
	|	// Director
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.GeneralManager )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|			) as Director
	|	on true
	|where Individuals.Ref in ( select Individual from Employees )
	|;
	|// Payroll
	|select Payroll.Ref as Ref
	|into Payroll
	|from Document.Payroll as Payroll
	|where Payroll.Ref.Posted
	|and Payroll.Ref.Date between &DateStart and &DateEnd
	|;
	|// #Payroll
	|select Payroll.DateStart as Begin, Payroll.DateEnd as End, Payroll.Ref.Date as Month, Payroll.AccountingResult as Amount, Personnel.Post.PositionCode as Post, 
	|	isnull ( NormDays.Days, 0 ) as Days, isnull ( Social.Amount, 0 ) as SocialAmount, isnull ( SocialEmployee.Amount, 0 ) as SocialEmployeeAmount,
	|	case when Payroll.Compensation.Method = value ( Enum.Calculations.SickDays ) then Payroll.AccountingResult else 0 end as SickAmount,
	|	case when Payroll.Compensation.Method = value ( Enum.Calculations.SickDays ) 
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.SickDaysChild )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.SickProduction )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.Vacation )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.ExtendedVacation )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.PaternityVacation )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.ChildCare )
	|		or Payroll.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) then false
	|		else true 
	|	end as Salary, Settings.Value.Code as Category
	|from Document.Payroll.Compensations as Payroll
	|	//
	|	// Personnel
	|	//
	|	left join Personnel as Personnel
	|	on true
	|	//
	|	// Norm
	|	//
	|	left join (
	|		select distinct count ( Schedules.Day ) as Days
	|		from InformationRegister.Schedules as Schedules
	|		where Schedules.Schedule in ( select Schedule from Personnel )
	|		and Schedules.Day between &SheduleBegin and &SheduleEnd
	|		and Schedules.Duration + Schedules.DurationEvening + Schedules.Minutes + Schedules.MinutesEvening + Schedules.MinutesNight > 0
	|			) as NormDays
	|	on true
	|	//
	|	// Social
	|	//
	|	left join (
	|		select Taxes.DateStart as DateStart, Taxes.DateEnd as DateEnd, sum ( Taxes.Result ) as Amount
	|		from Document.Payroll.Taxes as Taxes
	|		where Taxes.Ref in ( select Ref from Payroll )
	|		and Taxes.Individual in ( select Individual from Employees )
	|		and Taxes.Tax.Method = value ( Enum.Calculations.SocialInsurance )
	|		group by Taxes.DateStart, Taxes.DateEnd
	|			) as Social
	|	on beginofperiod ( Social.DateStart, day ) = beginofperiod ( Payroll.DateStart, day )
	|	and beginofperiod ( Social.DateEnd, day ) = beginofperiod ( Payroll.DateEnd, day )
	|	//
	|	// SocialEmployee
	|	//
	|	left join (
	|		select Taxes.DateStart as DateStart, Taxes.DateEnd as DateEnd, sum ( Taxes.Result ) as Amount
	|		from Document.Payroll.Taxes as Taxes
	|		where Taxes.Ref in ( select Ref from Payroll )
	|		and Taxes.Individual in ( select Individual from Employees )
	|		and Taxes.Tax.Method = value ( Enum.Calculations.SocialInsuranceEmployee )
	|		group by Taxes.DateStart, Taxes.DateEnd
	|			) as SocialEmployee
	|	on beginofperiod ( SocialEmployee.DateStart, day ) = beginofperiod ( Payroll.DateStart, day )
	|	and beginofperiod ( SocialEmployee.DateEnd, day ) = beginofperiod ( Payroll.DateEnd, day )
	|	//
	|	// Settings
	|	//
	|	left join InformationRegister.Settings.SliceLast ( &DateEnd ) as Settings
	|	on case 
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.SickDays ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.SickDays )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.SickDaysChild ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.SickDaysChild )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.SickProduction ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.SickProduction )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.Vacation ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.Vacation )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.ExtendedVacation ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.ExtendedVacation )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.PaternityVacation ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.PaternityVacation )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.ChildCare ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.ChildCare )
	|		when Payroll.Compensation.Method = value ( Enum.Calculations.ExtraChildCare ) 
	|			then Settings.Parameter = value ( ChartOfCharacteristicTypes.Settings.ExtraChildCare )
	|	end
	|where Payroll.Ref in ( select Ref from Payroll )
	|and Payroll.Individual in ( select Individual from Employees )
	|order by Payroll.Ref.Date, Payroll.DateStart, Payroll.DateEnd
	|;
	|// #Insurance
	|select  Insurance.Period as Period, Insurance.Category as Category 
	|	from (
	|	select Insurance.Period as Period, Insurance.Category.Code as Category
	|	from InformationRegister.Insurance as Insurance
	|	where Insurance.Period between &DateStart and &DateEnd
	|	and Insurance.Employee in ( select Employee from Employees )
	|	union all
	|	// InsuranceSlice
	|	select Insurance.Period as Period, Insurance.Category.Code as Category
	|	from InformationRegister.Insurance.SliceLast ( &DateStart, Employee in ( select Employee from Employees ) ) as Insurance
	|		) as Insurance
	|group by Insurance.Period, Insurance.Category
	|order by Insurance.Period
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
	q.SetParameter ( "Employee", get ( "Employee" ) );
	q.SetParameter ( "EmployeeCode", get ( "EmployeeCode" ) );
	if ( DateStart = BegOfYear ( DateStart )
		and DateEnd = EndOfYear ( DateStart ) ) then
		FieldsValues [ "Year" ] = true;
	endif;
	sheduleBegin = BegOfWeek ( AddMonth ( BegOfYear ( DateStart ), 1 ) );
	q.SetParameter ( "SheduleBegin", sheduleBegin );
	q.SetParameter ( "Sheduleend", EndOfWeek ( sheduleBegin ) );
	infoSettings = InformationRegisters.Settings;
	typesSettings = ChartsOfCharacteristicTypes.Settings;
	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;	
	
	// Default Values
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	
	// Flags
	FieldsValues [ "P20" ] = true;
	FieldsValues [ "P21" ] = false;
	FieldsValues [ "P22" ] = false;
	
	FieldsValues [ "A30" ] = true;
	FieldsValues [ "B30" ] = false;
	
	// Fill Table
	table = Env.Payroll;
	categories = table.Copy ( , "Begin" );
	categories.GroupBy ( "Begin" );
	for each row in categories do
		row.Begin = BegOfMonth ( row.Begin );
	enddo;
	categories.GroupBy ( "Begin" );
	categories.Columns.Add ( "Category" );
	insurance = Env.Insurance;
	for each rowCategory in categories do
		for each row in insurance do
			if ( rowCategory.Begin >= row.Period ) then
				rowCategory.Category = row.Category;
			endif;
		enddo;
	enddo;
	i = 1;
	for each row in table do
		FieldsValues [ "Line" + i ] = i;
		month = Format ( row.Month, "L = 'ro_RO';DF='MMMM'" );
		FieldsValues [ "Month" + i ] = Upper ( Left ( month, 1 ) ) + Right ( month, StrLen ( month ) - 1 );
		FieldsValues [ "Begin" + i ] = row.Begin;
		FieldsValues [ "End" + i ] = row.End;
		FieldsValues [ "Days" + i ] = row.Days;
		FieldsValues [ "Post" + i ] = row.Post;
		FieldsValues [ "A" + i ] = row.Amount;
		FieldsValues [ "B" + i ] = row.SickAmount;
		FieldsValues [ "C" + i ] = row.SocialEmployeeAmount;
		FieldsValues [ "D" + i ] = row.SocialAmount;
		if ( row.Salary ) then
			rowCategory = categories.Find ( BegOfMonth ( row.Begin ), "Begin" );
			if ( rowCategory <> undefined ) then
				FieldsValues [ "Category" + i ] = rowCategory.Category;
			endif;	
		else
			FieldsValues [ "Category" + i ] = row.Category;
		endif;
		i = i + 1;
	enddo;
	
	~draw:

	area = getArea ();
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.PrintArea = TabDoc.Area ( "R3:R76" );
	endif; 

EndProcedure

Procedure P20 ()
	
	if ( InternalProcessing ) then
		value1 = get ( "P21" );
		value2 = get ( "P22" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P20", true );
	else
		result = get ( "P20" );	
	endif;

EndProcedure

Procedure P21 ()

	if ( InternalProcessing ) then
		value1 = get ( "P20" );
		value2 = get ( "P22" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P21", true );
	else
		result = get ( "P21" );		
	endif;

EndProcedure

Procedure P22 ()

	if ( InternalProcessing ) then
		value1 = get ( "P20" );
		value2 = get ( "P21" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value2 and not value1;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P22", true );
	else
		result = get ( "P22" );		
	endif;

EndProcedure

Procedure Amount ()

	result = sum ( "A1:A24" );

EndProcedure

Procedure SickAmount ()

	result = sum ( "B1:B24" );

EndProcedure

Procedure SocialEmployee ()

	result = sum ( "C1:C24" );

EndProcedure

Procedure SocialCompany ()

	result = sum ( "D1:D24" );

EndProcedure

