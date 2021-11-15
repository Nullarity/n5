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
	
	FieldsValues [ "Period" ] = "A/" + Format ( DateEnd, "DF='yyyy'" );
	
	// Table
	line = 1;
	rowNumber = 78;
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
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure C20 ()

	result = ( get ( "A20" ) - get ( "B20" ) ) * 0.15;

EndProcedure

Procedure D20 ()

	result = get ( "A20" ) - get ( "B20" ) - get ( "C20" );

EndProcedure

Procedure C21 ()

	result = ( get ( "A21" ) - get ( "B21" ) ) * 0.15;

EndProcedure

Procedure D21 ()

	result = get ( "A21" ) - get ( "B21" ) - get ( "C21" );

EndProcedure

Procedure C22 ()

	result = ( get ( "A22" ) - get ( "B22" ) ) * 0.15;

EndProcedure

Procedure D22 ()

	result = get ( "A22" ) - get ( "B22" ) - get ( "C22" );

EndProcedure

Procedure C23 ()

	result = ( get ( "A23" ) - get ( "B23" ) ) * 0.15;

EndProcedure

Procedure D23 ()

	result = get ( "A23" ) - get ( "B23" ) - get ( "C23" );

EndProcedure

Procedure D24 ()

	result = sum ( "D20:D23" );

EndProcedure

Procedure A48 ()

	result = sum ( "A40:A47" );

EndProcedure

Procedure D98 ()

	result = sum ( "D78:D97" );

EndProcedure

Procedure E98 ()

	result = sum ( "E78:E97" );

EndProcedure

Procedure F98 ()

	result = sum ( "F78:F97" );

EndProcedure

Procedure G98 ()

	result = sum ( "G78:G97" );

EndProcedure

Procedure H98 ()

	result = sum ( "H78:H97" );

EndProcedure

Procedure I98 ()

	result = sum ( "I78:I97" );

EndProcedure

Procedure K98 ()

	result = sum ( "K78:K97" );

EndProcedure

Procedure L98 ()

	result = sum ( "L78:L97" );

EndProcedure

Procedure M98 ()

	result = sum ( "M78:M97" );

EndProcedure

Procedure N98 ()

	result = sum ( "N78:N97" );

EndProcedure

Procedure O98 ()

	result = sum ( "O78:O97" );

EndProcedure

Procedure P98 ()

	result = sum ( "P78:P97" );

EndProcedure

Procedure B188 ()

	result = sum ( "B182:B187" );

EndProcedure

Procedure C188 ()

	result = sum ( "C182:C187" );

EndProcedure

Procedure C204 ()

	result = sum ( "C201:C203" );

EndProcedure

Procedure D204 ()

	result = sum ( "D201:D203" );

EndProcedure