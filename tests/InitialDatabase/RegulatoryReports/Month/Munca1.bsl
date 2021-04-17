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
	month = Month ( DateEnd );
	if ( month >= 1 and month <= 3 ) then
		trim = "I";
	elsif ( month >= 4 and month <= 6 ) then
		trim = "II";
	elsif ( month >= 7 and month <= 9 ) then
		trim = "III";
	else
		trim = "IV";
	endif;		
	FieldsValues [ "Period" ] = trim + " " + Format ( DateStart, "DF='yyyy'" );
	
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

Procedure A33 ()

	Result = sum ( "A34:A35" );

EndProcedure

Procedure B33 ()

	Result = sum ( "B34:B35" );

EndProcedure

Procedure C33 ()

	Result = sum ( "C34:C35" );

EndProcedure

Procedure D33 ()

	Result = sum ( "D34:D35" );

EndProcedure

Procedure E33 ()

	Result = sum ( "E34:E35" );

EndProcedure

Procedure F33 ()

	Result = sum ( "F34:F35" );

EndProcedure

Procedure G33 ()

	Result = sum ( "G34:G35" );

EndProcedure

Procedure H33 ()

	Result = sum ( "H34:H35" );

EndProcedure

Procedure K33 ()

	Result = sum ( "K34:K35" );

EndProcedure

Procedure L33 ()

	Result = sum ( "L34:L35" );

EndProcedure

Procedure M33 ()

	Result = sum ( "M34:M35" );

EndProcedure

Procedure N33 ()

	Result = sum ( "N34:N35" );

EndProcedure

Procedure A43 ()

	_30 = get ( "A30" );
	Result = ( ( get ( "A37" ) - get ( "A40" ) ) / ? ( _30 = 0, 1, _30 ) ) * 1000;

EndProcedure

Procedure B43 ()

	_30 = get ( "B30" );
	Result = ( ( get ( "B37" ) - get ( "B40" ) ) / ? ( _30 = 0, 1, _30 ) ) * 1000;

EndProcedure