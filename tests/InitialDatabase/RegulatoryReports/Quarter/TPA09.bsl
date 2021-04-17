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
	FieldsValues [ "B37" ] = getLast ( "B37" );
	
	// Table
	line = 1;
	rowNumber = 73;
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

	result = get ( "B37" ) * get ( "A37" );

EndProcedure

Procedure F37 ()

	result = get ( "C37" ) - get ( "D37" );

EndProcedure

Procedure D103 ()

	result = sum ( "D73:D102" );

EndProcedure