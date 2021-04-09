Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.HomePhone as HomePhone,
	|	Director.Name as Director
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
	|where Companies.Ref = &Company
	|;
	|// #Turnovers
	|select Turnovers.AmountTurnoverCr as Value, ""Current"" as Key
	|from AccountingRegister.General.Turnovers ( beginofperiod ( &DateEnd, month ), endofperiod ( &DateEnd, month ), , 
	|	substring ( Account.Code, 1, 3 ) = ""611"", , Company = &Company, ) as Turnovers
	|";
	Env.Selection.Add ( str );	
	
	getData ();
	
	envFields = Env.Fields;
	
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	FieldsValues [ "Director" ] = envFields.Director;
	FieldsValues [ "Accountant" ] = envFields.Accountant;
	FieldsValues [ "HomePhone" ] = envFields.HomePhone;
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	FieldsValues [ "CUIO" ] = get ( "CUIO", "DefaultValues" );
	FieldsValues [ "Period" ] = Format ( DateEnd, "L = 'ro_RO';DF='MMMM yyyy'" );
	
	assignField ( "A26", "Current", "Turnovers" );
	
	//Last
	FieldsValues [ "Province" ] = getLast ( "Province" );
	FieldsValues [ "Street" ] = getLast ( "Street" );
	FieldsValues [ "Apartment" ] = getLast ( "Apartment" );
	
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A47 ()

	Result = sum ( "A48:A49" );

EndProcedure

Procedure B47 ()

	Result = sum ( "B48:B49" );

EndProcedure

Procedure C47 ()

	Result = sum ( "C48:C49" );

EndProcedure

Procedure D47 ()

	Result = sum ( "D48:D49" );

EndProcedure

Procedure E47 ()

	Result = sum ( "E48:E49" );

EndProcedure

Procedure F47 ()

	Result = sum ( "F48:F49" );

EndProcedure

Procedure A67 ()

	_30 = get ( "A44" );
	if ( _30 = 0 ) then
		Result = 0;
	else
		Result = ( ( get ( "A61" ) - get ( "A64" ) ) / _30 ) * 1000;
	endif;	

EndProcedure

Procedure B67 ()

	_30 = get ( "B44" );
	if ( _30 = 0 ) then
		Result = 0;
	else
		Result = ( ( get ( "B61" ) - get ( "B64" ) ) / _30 ) * 1000;
	endif;

EndProcedure