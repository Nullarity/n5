Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// Employee
	|select Employees.Individual as Individual, Employees.Description as Employee
	|into Employees
	|from Catalog.Employees as Employees
	|where  ( Employees.Individual.Description = &Employee or Employees.Individual.Code = &EmployeeCode )
	|;
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Employees.Employee as Employee,
	|	Accountant.Name as Accountant, Director.Name as Director
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name
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
	|	//
	|	// Employee
	|	//
	|	left join Employees as Employees
	|	on true
	|where Companies.Ref = &Company
	|;
	|// Compensations
	|select Compensations.Account as Account, Compensations.Ref as Salary
	|into Compensations
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where Compensations.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) )
	|and not Compensations.DeletionMark
	|;
	|// #Salary
	|select ""SalaryPayed"" as Key, Turnovers.AmountTurnoverDr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from Compensations ), , Company = &Company
	|							and ExtDimension2 in ( select Salary from Compensations )
	|							and ExtDimension1 in ( select Individual from Employees ) , ) as Turnovers
	|;
	|// #Medical
	|select ""MedicalEmployee"" as Key, Turnovers.AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , 
	|		Account in ( 
	|			select Taxes.Account as Account
	|			from ChartOfCalculationTypes.Taxes as Taxes
	|			where Taxes.Method = value ( Enum.Calculations.MedicalInsuranceEmployee )
	|			and not Taxes.DeletionMark 
	|					), , 
	|		Company = &Company
	|		and BalancedExtDimension1 in ( select Individual from Employees ), 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|;
	|// #Social
	|select ""SocialEmployee"" as Key, Turnovers.AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account = &EmployeesOtherDebt, , Company = &Company
	|		and BalancedExtDimension1 in ( select Individual from Employees ), 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|;
	|// #IncomeTax
	|select ""IncomeTax"" as Key, Turnovers.AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , 
	|		Account in ( 
	|			select Taxes.Account as Account
	|			from ChartOfCalculationTypes.Taxes as Taxes
	|			where Taxes.Method = value ( Enum.Calculations.IncomeTax ) or Taxes.Method = value ( Enum.Calculations.FixedIncomeTax )
	|			and not Taxes.DeletionMark 
	|					), , 
	|		Company = &Company
	|		and BalancedExtDimension1 in ( select Individual from Employees ), 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|";
	Env.Selection.Add ( str );	
	
	q = Env.Q;
 	q.SetParameter ( "EmployeesOtherDebt", InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.EmployeesOtherDebt ) ).Value );
 	q.SetParameter ( "Employee", get ( "EmployeeInput" ) );
	q.SetParameter ( "EmployeeCode", get ( "EmployeeCode" ) );
 	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "Period" ] = Format ( DateEnd, "L=Ro_ro;DF='dd MMMM yyyy'" );
	FieldsValues [ "PeriodRu" ] = Format ( DateEnd, "L=Ru_ru;DF='dd MMMM yyyy'" );
	FieldsValues [ "Year" ] = Format ( DateEnd, "DF='yyyy'" );
 
	// Salary
	assignField ( "SalaryPayed", "SalaryPayed", "Salary" );
	
	//Taxes
	assignField ( "MedicalEmployee", "MedicalEmployee", "Medical" );
	assignField ( "SocialEmployee", "SocialEmployee", "Social" );
	assignField ( "IncomeTax", "IncomeTax", "IncomeTax" );
	
	~draw:

	area = getArea ();	
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   		TabDoc.PrintArea = TabDoc.Area ( "R4:R47" );
   	endif;

EndProcedure