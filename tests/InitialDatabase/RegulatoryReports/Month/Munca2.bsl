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
	FieldsValues [ "Period" ] = Format ( DateStart, "L = 'ro_RO';DF='MMMM yyyy'" );
	FieldsValues [ "A23" ] = "";
	FieldsValues [ "B23" ] = "";
	FieldsValues [ "C23" ] = "";
	FieldsValues [ "D23" ] = "";
	FieldsValues [ "E23" ] = "";
	
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
