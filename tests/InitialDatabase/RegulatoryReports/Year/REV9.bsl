Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Director.Name as Director
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
	|where Companies.Ref = &Company
	|;
	|// SalaryAccounts
	|select Compensations.Account as Account
	|into SalaryAccounts
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where Compensations.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) )
	|and not Compensations.DeletionMark
	|;
	|// #Salary
	|select Turnovers.AmountTurnoverCr as TurnoverCr, Turnovers.AmountTurnoverDr as TurnoverDr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from SalaryAccounts ), , Company = &Company, ) as Turnovers
	|;
	|// #SocialCompany
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( 
	|								select Taxes.Account as Account
	|								from ChartOfCalculationTypes.Taxes as Taxes
	|								where Taxes.Method = value ( Enum.Calculations.SocialInsurance )
	|								and not Taxes.DeletionMark ), , Company = &Company, ) as Turnovers
	|;
	|// #SocialEmployee
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( 
	|								select Taxes.Account as Account
	|								from ChartOfCalculationTypes.Taxes as Taxes
	|								where Taxes.Method = value ( Enum.Calculations.SocialInsuranceEmployee )
	|								and not Taxes.DeletionMark ), , Company = &Company, 
	|		BalancedAccount in ( select Account from SalaryAccounts ),  ) as Turnovers
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
 	q.SetParameter ( "Company", Company );
 	getData ();
	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	// Default values
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
		
	FieldsValues [ "YearPeriod" ] = Year ( DateEnd );
	
	// Salary
	FieldsValues [ "Salary" ] = Env.Salary.Total ( "TurnoverCr" );
	//Taxes
	FieldsValues [ "SocialCompany" ] = Env.SocialCompany.Total ( "TurnoverCr" );
	FieldsValues [ "SocialEmployee" ] = Env.SocialEmployee.Total ( "TurnoverCr" );
	
	FieldsValues [ "SocialEmployeeNet" ] = FieldsValues [ "SocialEmployee" ];
	FieldsValues [ "SocialCompanyNet" ] = FieldsValues [ "SocialCompany" ];
	
	
	FieldsValues [ "A8" ] = true;
	FieldsValues [ "A9" ] = false;
	FieldsValues [ "A10" ] = false;
	
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A8 ()

	_name = "A8";
	if ( InternalProcessing ) then
		value1 = get ( "A9" );
		value2 = get ( "A10" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;		
		RegulatoryReports.SaveUserValue ( Ref, result, _name, true );
	else
		result = get ( _name );		
	endif;

EndProcedure

Procedure A9 ()

	_name = "A9";
	if ( InternalProcessing ) then
		value1 = get ( "A8" );
		value2 = get ( "A10" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;		
		RegulatoryReports.SaveUserValue ( Ref, result, _name, true );
	else
		result = get ( _name );		
	endif;

EndProcedure

Procedure A10 ()

	_name = "A10";
	if ( InternalProcessing ) then
		value1 = get ( "A8" );
		value2 = get ( "A9" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;		
		RegulatoryReports.SaveUserValue ( Ref, result, _name, true );
	else
		result = get ( _name );		
	endif;

EndProcedure

Procedure PercentEmployee ()

	socialEmployee = get ( "SocialEmployee" );
	if ( socialEmployee = 0 ) then
		result = 0;
	else
		result = get ( "SocialEmployeeNet" ) / socialEmployee * 100;		
	endif;

EndProcedure

Procedure PercentCompany ()

	socialCompany = get ( "SocialCompany" );
	if ( socialCompany = 0 ) then
		result = 0;
	else
		result = get ( "SocialCompanyNet" ) / socialCompany * 100;		
	endif;

EndProcedure