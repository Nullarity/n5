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
	|// #Turnovers
	|select sum ( Turnovers.AmountTurnoverCr ) as Value, substring ( Turnovers.Account.Code, 1, 4 ) as Key
	|from AccountingRegister.General.Turnovers ( beginofperiod ( &DateStart, year ), endofperiod ( &DateStart, year ), , substring ( Account.Code, 1, 4 ) in ( &Accounts ), , Company = &Company, ) as Turnovers
	|group by substring ( Turnovers.Account.Code, 1, 4 )
	|";
	Env.Selection.Add ( str );	
	q = Env.Q;
 	q.SetParameter ( "Company", Company );
 	
 	mapField ( "A36", "6111, 6112", "Accounts", "Turnovers" );
 	mapField ( "A37", "6113, 6114", "Accounts", "Turnovers" );
 	mapField ( "A39", "6121", "Accounts", "Turnovers" );
 	mapField ( "A40", "6124", "Accounts", "Turnovers" );
 	mapField ( "A41", "6122", "Accounts", "Turnovers" );
 	mapField ( "A42", "6125", "Accounts", "Turnovers" );
 	mapField ( "A44", "6115, 6116, 6117, 6118, 6123, 6126", "Accounts", "Turnovers" );
	
	getData ();
	
	envFields = Env.Fields;
	
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "KindOfActivity" ] = get ( "KindOfActivity", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "Period" ] = "A/" + Format ( DateStart, "DF='yyyy'" );
	
	~draw:
	
	area = getArea ();
	draw ();
	TabDoc.FitToPage = true;

EndProcedure

Procedure A45 ()

	Result = sum ( "A36:A44" );

EndProcedure

Procedure A47 ()

	Result = get ( "A45" ) * get ( "A46" ) / 100;

EndProcedure

Procedure A49 ()

	Result = get ( "A47" ) - get ( "A48" ) ;

EndProcedure
