Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Director.Name as Director,
	|	Accountant.HomePhone as HomePhone, Addresses.Address as Address
	|from Catalog.Companies as Companies
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
	|	//
	|	// Addresses
	|	//
	|	left join (
	|	select top 1 Addresses.Presentation as Address
	|	from Catalog.Addresses as Addresses
	|	where Addresses.Owner = &Company
	|	and not Addresses.DeletionMark
	|			) as Addresses
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
	|select Turnovers.AmountTurnoverCr as TurnoverCr, Turnovers.AmountTurnoverDr as TurnoverDr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from Compensations ), , Company = &Company
	|							and ExtDimension2 in ( select Salary From Compensations ), ) as Turnovers
	|;
	|// SocialAccounts
	|select Taxes.Account as Account
	|into SocialAccounts
	|from ChartOfCalculationTypes.Taxes as Taxes
	|where Taxes.Method = value ( Enum.Calculations.SocialInsurance )
	|and not Taxes.DeletionMark 
	|;
	|// #SocialCompany
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from SocialAccounts ), , Company = &Company, ) as Turnovers
	|;
	|// #SocialEmployee
	|select Turnovers.AmountTurnoverDr as TurnoverDr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account = &EmployeesOtherDebt, , Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|;
	|// SickDays
	|select Compensations.Ref as Ref
	|into SickDays
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where Compensations.Method = value ( Enum.Calculations.SickDays )
	|and not Compensations.DeletionMark
	|;
	|// #SickDaysBass
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , , , Company = &Company
	|		and ExtDimension2 in ( select Ref from SickDays ), BalancedAccount in ( select Account from SocialAccounts ),  ) as Turnovers
	|;
	|// #SickDaysCompany
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , , , Company = &Company
	|		and ExtDimension2 in ( select Ref from SickDays ), BalancedAccount not in ( select Account from SocialAccounts ),  ) as Turnovers
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
 	q.SetParameter ( "EmployeesOtherDebt", InformationRegisters.Settings.GetLast ( , new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.EmployeesOtherDebt ) ).Value );
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
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
		
	FieldsValues [ "Year" ] = Year ( DateEnd );
	FieldsValues [ "Month" ] = Month ( DateEnd );
	
	// Salary
	FieldsValues [ "Salary" ] = Env.Salary.Total ( "TurnoverCr" );
	//Taxes
	FieldsValues [ "SocialCompany" ] = Env.SocialCompany.Total ( "TurnoverCr" );
	FieldsValues [ "SocialEmployee" ] = Env.SocialEmployee.Total ( "TurnoverDr" );
	
	//SickDays
	FieldsValues [ "CalculatedBass" ] = Env.SickDaysBass.Total ( "TurnoverCr" );
	FieldsValues [ "CalculatedCompany" ] = Env.SickDaysCompany.Total ( "TurnoverCr" );
	
	FieldsValues [ "A20" ] = true;
	FieldsValues [ "B20" ] = false;
	
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A20 ()

	result = not get ( "B20" );	
	RegulatoryReports.SaveUserValue ( Ref, result, "A20", true );

EndProcedure

Procedure B20 ()

	result = not get ( "A20" );	
	RegulatoryReports.SaveUserValue ( Ref, result, "B20", true );

EndProcedure

Procedure C50 ()

	result = Round ( get ( "SocialEmployee" ) / 0.06, 2 );
	
EndProcedure

Procedure D51 ()

	result = get ( "SocialCompany" ) + sum ( "D42:D43" ) + sum ( "D45:D47" );
	
EndProcedure
Procedure E51 ()

	result = get ( "E48" ) + get ( "SocialEmployee" );
	
EndProcedure

Procedure A69 ()

	result = get ( "DaysBass" ) + get ( "A65" ) + sum ( "A67:A68" );

EndProcedure

Procedure B69 ()

	result = get ( "EmployeesBass" ) + get ( "B65" ) + sum ( "B67:B68" );

EndProcedure

Procedure C69 ()

	result = get ( "CalculatedBass" ) + get ( "C65" ) + sum ( "C67:C68" );

EndProcedure

Procedure D69 ()

	result = get ( "PayedBass" ) + get ( "D65" ) + sum ( "D67:D68" );

EndProcedure