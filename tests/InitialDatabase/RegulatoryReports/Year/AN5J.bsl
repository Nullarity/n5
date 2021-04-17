Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// Organization
	|select top 1 Organizations.Ref as Ref, Organizations.FullDescription as FullDescription
	|into Organizations
	|from Catalog.Organizations as Organizations
	|where case when &OrganizationInput = """" then false else Organizations.Description = &OrganizationInput end 
	|	or case when &CodeFiscal = """" then false else Organizations.CodeFiscal = &CodeFiscal end
	|;
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Organizations.FullDescription as Organization,
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
	|	// Organizations
	|	//
	|	left join Organizations as Organizations
	|	on true
	|where Companies.Ref = &Company
	|;
	|// Income
	|select sum ( Turnovers.AmountTurnoverCr ) as Amount, Turnovers.BalancedAccount as Account, Turnovers.ExtDimension1 as Code, Turnovers.Recorder as Recorder
	|into Income
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account.Code = ""5343"", , Company = &Company
	|		and BalancedExtDimension1 in ( select Ref from Organizations ) and ExtDimension1 <> value ( Enum.IncomeCodes.EmptyRef ), ,  ) as Turnovers
	|group by Turnovers.BalancedAccount, Turnovers.ExtDimension1, Turnovers.Recorder
	|;
	|// Base
	|select sum ( Turnovers.AmountTurnoverDr ) as Amount, Income.Code as Code
	|into Base
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account in ( select Account from Income ), , Company = &Company
	|		and ExtDimension1 in ( select Ref from Organizations ), ,  ) as Turnovers
	|	// 
	|	// Income
	|	// 
	|	left join Income as Income
	|	on Income.Recorder = Turnovers.Recorder
	|where Turnovers.Recorder in ( select Recorder from Income )
	|group by Income.Code 
	|;
	|// #Table
	|select Income.Amount as IncomeAmount, presentation ( Income.Code ) as Code, Base.Amount as BaseAmount
	|from ( select sum ( Income.Amount ) as Amount, Income.Code as Code
	|		from Income as Income
	|		group by Income.Code
	|	  ) as Income
	|	// 
	|	// Base
	|	// 
	|	left join Base as Base
	|	on Base.Code = Income.Code
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
	|";
	Env.Selection.Add ( str );	
	
	q = Env.Q;
 	q.SetParameter ( "OrganizationInput", get ( "OrganizationInput" ) );
	q.SetParameter ( "CodeFiscal", get ( "CodeFiscal" ) );
 	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "Period" ] = DateEnd;
	FieldsValues [ "Year" ] = Format ( DateEnd, "DF='yyyy'" );
	
	// Fill Table
	i = 29;
	for each row in Env.Table do
		FieldsValues [ "A" + i ] = row.Code;
		FieldsValues [ "B" + i ] = row.BaseAmount;
		FieldsValues [ "E" + i ] = row.IncomeAmount;
		i = i + 1;
	enddo;
		
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   		TabDoc.PrintArea = TabDoc.Area ( "R4:R53" );
   	endif;

EndProcedure