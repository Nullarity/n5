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
	|// MedicalTaxes
	|select Taxes.Ref as Tax, Taxes.Account as Account
	|into MedicalTaxes
	|from ChartOfCalculationTypes.Taxes as Taxes
	|where Taxes.Method = value ( Enum.Calculations.MedicalInsurance )
	|and not Taxes.DeletionMark
	|;
	|// @Taxes
	|select top 1 Taxes.Rate as Rate
	|from InformationRegister.PayrollTaxes.SliceLast 
	|			( &DateEnd, 
	|			Tax in ( select Tax from MedicalTaxes )
	|			and Use ) as Taxes
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
	|// #MedicalEmployee
	|select Turnovers.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from MedicalTaxes ), , Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
 	getData ();
	
	envFields = Env.Fields;
	// Fields
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	// Default values
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	
	month = Month ( BegOfQuarter ( DateStart ) );
 	if ( month = 1 ) then
 		quarter = "1";
 	elsif ( month = 4 ) then
 		quarter = "2";
 	elsif ( month = 7 ) then
 		quarter = "3";
 	else
 		quarter = "4";
 	endif;
	
	FieldsValues [ "Period" ] = "T/" + quarter + "/" + Format ( DateEnd, "DF='yyyy'" );
	
	// Rate
	taxes = Env.Taxes;
	if ( taxes <> undefined ) then
		FieldsValues [ "Rate" ] = taxes.Rate;
	endif;
	
	// Salary
	table = Env.Salary;
	FieldsValues [ "SalaryCalculated" ] = table.Total ( "TurnoverCr" );
	FieldsValues [ "SalaryPayed" ] = table.Total ( "TurnoverDr" ); 
	
	//Taxes
	FieldsValues [ "C37" ] = 0;
	FieldsValues [ "C38" ] = Env.MedicalEmployee.Total ( "TurnoverCr" );
	
	~draw:
	
	area = getArea ();
	draw ();
	TabDoc.FitToPage = true;

EndProcedure

Procedure C39 ()

	Result = sum ( "C37:C38" );

EndProcedure