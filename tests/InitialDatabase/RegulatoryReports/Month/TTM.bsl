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
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	
	//L/04/2017
	
	FieldsValues [ "Period" ] = "L/" + Format ( DateStart, "DF='MM'" ) + "/" + Format ( DateStart, "DF='yyyy'" );
	
	// Previous
	FieldsValues [ "B29" ] = getLast ( "B29" );
	
	~draw:
	
	area = getArea ();
	draw ();

EndProcedure

Procedure C29 ()

	result = get ( "A29" ) * get ( "B29" ) / 100;

EndProcedure
