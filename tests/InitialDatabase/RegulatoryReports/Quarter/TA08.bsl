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
	for i = 24 to 26 do
		FieldsValues [ "B" + i ] = getLast ( "B" + i );
		FieldsValues [ "C" + i ] = getLast ( "C" + i );
	enddo;
	
	// Table
	line = 1;
	rowNumber = 54;
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

Procedure D27 ()

	result = sum ( "D24:D26" );

EndProcedure

Procedure E27 ()

	result = sum ( "E24:E26" );

EndProcedure

Procedure D70 ()

	result = sum ( "D54:D69" );

EndProcedure

Procedure E70 ()

	result = sum ( "E54:E69" );

EndProcedure

Procedure E24 ()

	result = ( ( get ( "A24" ) + get ( "B24" ) ) * get ( "C24" ) ) - get ( "D24" );

EndProcedure

Procedure E25 ()

	result = ( ( get ( "A25" ) + get ( "B25" ) ) * get ( "C25" ) ) - get ( "D25" );

EndProcedure

Procedure E26 ()

	result = ( ( get ( "A26" ) + get ( "B26" ) ) * get ( "C26" ) ) - get ( "D26" );

EndProcedure