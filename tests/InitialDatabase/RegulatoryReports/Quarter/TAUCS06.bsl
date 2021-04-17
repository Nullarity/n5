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
	FieldsValues [ "A37" ] = getLast ( "A37" );
	FieldsValues [ "A38" ] = getLast ( "A38" );
	
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

Procedure E37 ()

	result = get ( "B37" ) - get ( "C37" );

EndProcedure

Procedure E38 ()

	result = get ( "B38" ) - get ( "C38" );

EndProcedure

Procedure B39 ()

	result = sum ( "B37:B38" );

EndProcedure

Procedure C39 ()

	result = sum ( "C37:C38" );

EndProcedure

Procedure D39 ()

	result = sum ( "D37:D38" );

EndProcedure

Procedure E39 ()

	result = sum ( "E37:E38" );

EndProcedure

Procedure D104 ()

	result = sum ( "D74:D103" );

EndProcedure