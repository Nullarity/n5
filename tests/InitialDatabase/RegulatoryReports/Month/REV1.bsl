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
	|// @Fields
	|select Individuals.FirstName as FirstName, Individuals.LastName as LastName, Individuals.Patronymic as Patronymic,
	|	case when Individuals.Gender = value ( Enum.Sex.Male ) then true else False end as Male,
	|	case when Individuals.Gender = value ( Enum.Sex.Female ) then true else False end as Female, Statuses.Status as Status,
	|	day ( Individuals.Birthday ) as Day, month ( Individuals.Birthday ) as Month, year ( Individuals.Birthday ) as Year,
	|	Individuals.Birthplace.Country.Description as Country, Individuals.Birthplace.City.Description as City, Individuals.SIN as SIN,
	|	Individuals.Birthplace.State.Description as State, Individuals.Birthplace.Municipality as Municipality, Individuals.Birthplace.ZIP as ZIP,
	|	Individuals.Birthplace.Street as Street, Individuals.Birthplace.Number as House, Individuals.Birthplace.Building as Building,
	|	Individuals.Birthplace.Apartment as Apartment, Individuals.HomePhone as HomePhone, Employees.Employee.BusinessPhone as BusinessPhone,
	|	day ( ID.Issued ) as IssuedDay, month ( ID.Issued ) as IssuedMonth, ID.IssuedBy as IssuedBy, ID.Number as Number, ID.Series as Series, 
	|	year ( ID.Issued ) as IssuedYear, case when ID.Type = value ( Catalog.IDTypes.IdentityCard ) then true else false end as IdentityCard,
	|	case when ID.Type = value ( Catalog.IDTypes.OldPassport ) then true else false end as OldPassport,
	|	case when ID.Type = value ( Catalog.IDTypes.MAI ) then true else false end as MAI, Individuals.PIN as PIN, 
	|	day ( BirthID.Issued ) as BirthIssuedDay, month ( BirthID.Issued ) as BirthIssuedMonth, BirthID.IssuedBy as BirthIssuedBy, BirthID.Number as BirthNumber, 
	|	BirthID.Series as BirthSeries, year ( BirthID.Issued ) as BirthIssuedYear
	|from Catalog.Individuals as Individuals
	|	//
	|	// Statuses
	|	//
	|	left join ( 
	|		select top 1 Statuses.Status
	|		from InformationRegister.MaritalStatuses.SliceLast ( &DateEnd, Individual in ( select Individual from Employees ) ) as Statuses
	|		) as Statuses
	|	on true
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
	|	// BirthID
	|	//
	|	left join ( 
	|		select top 1 ID.Issued as Issued, ID.IssuedBy as IssuedBy, ID.Number as Number, ID.Series as Series
	|		from InformationRegister.ID.SliceLast ( &DateEnd, Individual in ( select Individual from Employees )
	|														  and Type = value ( Catalog.IDTypes.BirthCertificate ) ) as ID
	|		) as BirthID
	|	on true
	|where Individuals.Ref in ( select Individual from Employees )
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
	q.SetParameter ( "Employee", get ( "Employee" ) );
	q.SetParameter ( "EmployeeCode", get ( "EmployeeCode" ) );
 	getData ();
 	
 	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;	
	
	FieldsValues [ "P8" ] = true;
	FieldsValues [ "P9" ] = false;
	FieldsValues [ "P10" ] = false;
	
	FieldsValues [ "A30" ] = true;
	FieldsValues [ "B30" ] = false;
	
	~draw:
	
	area = getArea ();
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.PrintArea = TabDoc.Area ( "R4:R76" );
	endif; 

EndProcedure

Procedure P8 ()
	
	if ( InternalProcessing ) then
		p9 = get ( "P9" );
		p10 = get ( "P10" );
		if ( p9 = p10 ) and ( not p9 ) then
			result = false;
		else
			result = not p9 and not p10;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P8", true );
	else
		result = get ( "P8" );	
	endif;

EndProcedure

Procedure P9 ()

	if ( InternalProcessing ) then
		p8 = get ( "P8" );
		p10 = get ( "P10" );
		if ( p8 = p10 ) and ( not p8 ) then
			result = false;
		else
			result = not p8 and not p10;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P9", true );
	else
		result = get ( "P9" );		
	endif;

EndProcedure

Procedure P10 ()

	if ( InternalProcessing ) then
		p8 = get ( "P8" );
		p9 = get ( "P9" );
		if ( p8 = p9 ) and ( not p8 ) then
			result = false;
		else
			result = not p9 and not p8;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "P10", true );
	else
		result = get ( "P10" );		
	endif;

EndProcedure

Procedure Male ()

	if ( InternalProcessing ) then
		result = not get ( "Female" );
		RegulatoryReports.SaveUserValue ( Ref, result, "Male", true );
	else
   		result = get ( "Male" );
   	endif;	

EndProcedure

Procedure Female ()

	if ( InternalProcessing ) then
		result = not get ( "Male" );
		RegulatoryReports.SaveUserValue ( Ref, result, "Female", true );
   	else
   		result = get ( "Female" );
   	endif;
	

EndProcedure

Procedure A30 ()

	result = not get ( "B30" );
	RegulatoryReports.SaveUserValue ( Ref, result, "A30", true );

EndProcedure

Procedure B30 ()

	result = not get ( "A30" );
	RegulatoryReports.SaveUserValue ( Ref, result, "B30", true );

EndProcedure

Procedure IdentityCard ()
	
	if ( InternalProcessing ) then
		value1 = get ( "OldPassport" );
		value2 = get ( "MAI" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;	
		RegulatoryReports.SaveUserValue ( Ref, result, "IdentityCard", true );
	else
		result = get ( "IdentityCard" );	
	endif;

EndProcedure

Procedure OldPassport ()

	if ( InternalProcessing ) then
		value1 = get ( "IdentityCard" );
		value2 = get ( "MAI" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;		
		RegulatoryReports.SaveUserValue ( Ref, result, "OldPassport", true );
	else
		result = get ( "OldPassport" );		
	endif;

EndProcedure

Procedure MAI ()

	if ( InternalProcessing ) then
		value1 = get ( "IdentityCard" );
		value2 = get ( "OldPassport" );
		if ( value1 = value2 ) and ( not value1 ) then
			result = false;
		else
			result = not value1 and not value2;
		endif;		
		RegulatoryReports.SaveUserValue ( Ref, result, "MAI", true );
	else
		result = get ( "MAI" );		
	endif;

EndProcedure
