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
	|// #Divisions
	|select Divisions.Code as Code, Divisions.Cutam as Cutam
	|from Catalog.Divisions as Divisions
	|where not Divisions.DeletionMark
	|and Divisions.Owner = &Company
	|";
	Env.Selection.Add ( str );	
	getData ();

	// Fields
	envFields = Env.Fields;
	if ( envFields <> undefined ) then 
		for each item in envFields do
		 	FieldsValues [ item.Key ] = item.Value;
		enddo;
	endif;
	
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	
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
	
	// Previous
	FieldsValues [ "C35" ] = getLast ( "C35" );
	FieldsValues [ "C36" ] = getLast ( "C36" );
	
	// Table
	line = 1;
	rowNumber = 74;
	for each row in Env.Divisions do
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = row.Code;
		FieldsValues [ "C" + rowNumber ] = row.Cutam;
		line = line + 1;
		rowNumber = rowNumber + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	draw ();

EndProcedure

Procedure D104 ()

	result = sum ( "D74:D103" );

EndProcedure

Procedure E104 ()

	result = sum ( "E74:E103" );

EndProcedure

Procedure F104 ()

	result = sum ( "F74:F103" );

EndProcedure

Procedure D35 ()

	result = get ( "A35" ) * get ( "C35" ) / 100;

EndProcedure

Procedure D36 ()

	result = get ( "B36" ) * get ( "C36" );

EndProcedure

Procedure G35 ()

	result = get ( "D35" ) - get ( "E35" );

EndProcedure

Procedure G36 ()

	result = get ( "D36" ) - get ( "E36" );

EndProcedure

Procedure D37 ()

	result = sum ( "D35:D36" );

EndProcedure

Procedure E37 ()

	result = sum ( "E35:E36" );

EndProcedure

Procedure F37 ()

	result = sum ( "F35:F36" );

EndProcedure

Procedure G37 ()

	result = sum ( "G35:G36" );

EndProcedure