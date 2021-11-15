Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;

	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.HomePhone as HomePhone,
	|	Director.Name as Director, Accountant.Email as Email
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.HomePhone as HomePhone,
	|			Roles.User.Employee.Email as Email
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
	q = Env.Q;
 	q.SetParameter ( "Company", Company );
 	getData ();
	
	envFields = Env.Fields;
	// Fields
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	FieldsValues [ "Accountant" ] = envFields.Accountant;
	FieldsValues [ "Director" ] = envFields.Director;
	FieldsValues [ "HomePhone" ] = envFields.HomePhone;
	FieldsValues [ "Email" ] = envFields.Email;
	// Default values
	FieldsValues [ "KindOfActivity" ] = get ( "KindOfActivity", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "CFP" ] = get ( "CFP", "DefaultValues" );
	FieldsValues [ "CUIO" ] = get ( "CUIO", "DefaultValues" );
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	
	//Last
	FieldsValues [ "Province" ] = getLast ( "Province" );
	FieldsValues [ "Street" ] = getLast ( "Street" );
	FieldsValues [ "Apartment" ] = getLast ( "Apartment" );
	FieldsValues [ "OwnerType" ] = getLast ( "OwnerType" );
	
	FieldsValues [ "PeriodRo" ] = Format ( DateEnd, "L = 'ro_RO';DF='MMMM yyyy'" );
	FieldsValues [ "PeriodRu" ] = Format ( DateEnd, "L = 'ru_RU';DF='MMMM yyyy'" );
	
	~draw:
	
	area = getArea ();
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

