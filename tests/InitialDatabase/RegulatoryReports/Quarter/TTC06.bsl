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
	|order by Divisions.Code
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
	for i = 37 to 41 do
		FieldsValues [ "A" + i ] = getLast ( "A" + i );
		FieldsValues [ "B" + i ] = getLast ( "B" + i );
	enddo;
	
	// Table
	line = 1;
	rowNumber = 85;
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

Procedure C37 ()

	result = get ( "A37" ) * get ( "B37" );

EndProcedure

Procedure C38 ()

	result = get ( "A38" ) * get ( "B38" );

EndProcedure

Procedure C39 ()

	result = get ( "A39" ) * get ( "B39" );

EndProcedure

Procedure C40 ()

	result = get ( "A40" ) * get ( "B40" );

EndProcedure

Procedure C41 ()

	result = get ( "A41" ) * get ( "B41" );

EndProcedure

Procedure F37 ()

	result = get ( "C37" ) - get ( "D37" );

EndProcedure

Procedure F38 ()

	result = get ( "C38" ) - get ( "D38" );

EndProcedure

Procedure F39 ()

	result = get ( "C39" ) - get ( "D39" );

EndProcedure

Procedure F40 ()

	result = get ( "C40" ) - get ( "D40" );

EndProcedure

Procedure F41 ()

	result = get ( "C41" ) - get ( "D41" );

EndProcedure

Procedure C42 ()

	result = sum ( "C37:C41" );

EndProcedure

Procedure D42 ()

	result = sum ( "D37:D41" );

EndProcedure

Procedure E42 ()

	result = sum ( "E37:E41" );

EndProcedure

Procedure F42 ()

	result = sum ( "F37:F41" );

EndProcedure

Procedure D115 ()

	result = sum ( "D85:D114" );

EndProcedure