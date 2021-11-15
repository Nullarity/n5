Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;	

	str = "
	|// @Fields
	|select Companies.FullDescription as Company
	|from Catalog.Companies as Companies
	|where Companies.Ref = &Company
	|";
	Env.Selection.Add ( str );	
	getData ();

	FieldsValues [ "A84" ] = true;
	FieldsValues [ "B84" ] = false;
	
	FieldsValues [ "Company" ] = Env.Fields.Company;
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	FieldsValues [ "Year" ] = Format ( DateEnd, "DF='yyyy'" );

	~draw:
	area = getArea ();	
	draw ();

EndProcedure

Procedure A84 ()

	result = not get ( "B84" );
	RegulatoryReports.SaveUserValue ( Ref, result, "A84", true );

EndProcedure

Procedure B84 ()

	result = not get ( "A84" );
	RegulatoryReports.SaveUserValue ( Ref, result, "B84", true );

EndProcedure

Procedure A94 ()

	result = sum ( "A90:A93" );

EndProcedure