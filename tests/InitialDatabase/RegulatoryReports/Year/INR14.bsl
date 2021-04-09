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
	
	FieldsValues [ "Period" ] = "A/" + Format ( DateEnd, "DF='yyyy'" );
	
	// DefaultValues
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
		
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   	endif;

EndProcedure

Procedure H59 ()

	result = sum ( "H39:H58" );

EndProcedure

Procedure I59 ()

	result = sum ( "I39:I58" );

EndProcedure
