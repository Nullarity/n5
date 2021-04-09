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
	
 	FieldsValues [ "Period" ] = "T/0" + quarter + "/" + Format ( DateEnd, "DF='yyyy'" );
	
	// Previous
	for i = 31 to 34 do
		FieldsValues [ "A" + i ] = getLast ( "A" + i );
	enddo;
	
	// Table
	line = 1;
	rowNumber = 65;
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

Procedure A35 ()

	result = get ( "A32" ) - get ( "A33" ) - get ( "A34" );

EndProcedure

Procedure D85 ()

	result = sum ( "D65:D84" );

EndProcedure

Procedure E85 ()

	result = sum ( "E65:E84" );

EndProcedure

Procedure F85 ()

	result = sum ( "F65:F84" );

EndProcedure

Procedure G85 ()

	result = sum ( "G65:G84" );

EndProcedure

Procedure E153 ()

	result = sum ( "E147:E152" );

EndProcedure

Procedure F153 ()

	result = sum ( "F147:F152" );

EndProcedure

Procedure C168 ()

	result = sum ( "C165:C167" );

EndProcedure

Procedure D168 ()

	result = sum ( "D165:D167" );

EndProcedure