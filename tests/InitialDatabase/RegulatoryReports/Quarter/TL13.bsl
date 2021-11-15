Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal
	|from Catalog.Companies as Companies
	|where Companies.Ref = &Company
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
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
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
	
	~draw:
	
	area = getArea ();
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure C44 ()

	result = get ( "A44" ) * get ( "B44" );

EndProcedure

Procedure F44 ()

	result = get ( "C44" ) - get ( "D44" );

EndProcedure

Procedure C45 ()

	result = get ( "A45" ) * get ( "B45" );

EndProcedure

Procedure F45 ()

	result = get ( "C45" ) - get ( "D45" );

EndProcedure

Procedure C46 ()

	result = get ( "A46" ) * get ( "B46" );

EndProcedure

Procedure F46 ()

	result = get ( "C46" ) - get ( "D46" );

EndProcedure

Procedure C47 ()

	result = get ( "A47" ) * get ( "B47" );

EndProcedure

Procedure F47 ()

	result = get ( "C47" ) - get ( "D47" );

EndProcedure

Procedure C48 ()

	result = get ( "A48" ) * get ( "B48" );

EndProcedure

Procedure F48 ()

	result = get ( "C48" ) - get ( "D48" );

EndProcedure

Procedure C49 ()

	result = get ( "A49" ) * get ( "B49" );

EndProcedure

Procedure F49 ()

	result = get ( "C49" ) - get ( "D49" );

EndProcedure

Procedure C50 ()

	result = get ( "A50" ) * get ( "B50" );

EndProcedure

Procedure F50 ()

	result = get ( "C50" ) - get ( "D50" );

EndProcedure

Procedure C51 ()

	result = get ( "A51" ) * get ( "B51" );

EndProcedure

Procedure F51 ()

	result = get ( "C51" ) - get ( "D51" );

EndProcedure

Procedure C52 ()

	result = get ( "A52" ) * get ( "B52" );

EndProcedure

Procedure F52 ()

	result = get ( "C52" ) - get ( "D52" );

EndProcedure

Procedure C53 ()

	result = get ( "A53" ) * get ( "B53" );

EndProcedure

Procedure F53 ()

	result = get ( "C53" ) - get ( "D53" );

EndProcedure

Procedure C54 ()

	result = get ( "A54" ) * get ( "B54" );

EndProcedure

Procedure F54 ()

	result = get ( "C54" ) - get ( "D54" );

EndProcedure

Procedure C55 ()

	result = sum ( "C44:C54" );

EndProcedure

Procedure D55 ()

	result = sum ( "D44:D54" );

EndProcedure

Procedure E55 ()

	result = sum ( "E44:E54" );

EndProcedure

Procedure F55 ()

	result = sum ( "F44:F54" );

EndProcedure

Procedure E213 ()

	result = sum ( "E105:E112" ) + sum ( "E115:E122" ) + sum ( "E125:E132" ) + sum ( "E135:E142" ) + sum ( "E145:E152" ) + sum ( "E155:E162" ) + 
	sum ( "E165:E172" ) + sum ( "E175:E182" ) + sum ( "E185:E192" ) + sum ( "E195:E202" ) + sum ( "E205:E212" );

EndProcedure

Procedure F213 ()

	result = sum ( "F105:F112" ) + sum ( "F115:F122" ) + sum ( "F125:F132" ) + sum ( "F135:F142" ) + sum ( "F145:F152" ) + sum ( "F155:F162" ) + 
	sum ( "F165:F172" ) + sum ( "F175:F182" ) + sum ( "F185:F192" ) + sum ( "F195:F202" ) + sum ( "F205:F212" );

EndProcedure

Procedure G213 ()

	result = sum ( "G105:G112" ) + sum ( "G115:G122" ) + sum ( "G125:G132" ) + sum ( "G135:G142" ) + sum ( "G145:G152" ) + sum ( "G155:G162" ) + 
	sum ( "G165:G172" ) + sum ( "G175:G182" ) + sum ( "G185:G192" ) + sum ( "G195:G202" ) + sum ( "G205:G212" );

EndProcedure

Procedure H213 ()

	result = sum ( "H105:H112" ) + sum ( "H115:H122" ) + sum ( "H125:H132" ) + sum ( "H135:H142" ) + sum ( "H145:H152" ) + sum ( "H155:H162" ) + 
	sum ( "H165:H172" ) + sum ( "H175:H182" ) + sum ( "H185:H192" ) + sum ( "H195:H202" ) + sum ( "H205:H212" );

EndProcedure