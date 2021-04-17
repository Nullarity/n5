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
	
	FieldsValues [ "Period" ] = "A/" + Format ( DateStart, "DF='yyyy'" );
	
	// Previous
	for i = 45 to 46 do
		FieldsValues [ "F" + i ] = getLast ( "F" + i );
	enddo;
	for i = 52 to 57 do
		FieldsValues [ "F" + i ] = getLast ( "F" + i );
	enddo;
	for i = 66 to 68 do
		FieldsValues [ "F" + i ] = getLast ( "F" + i );
	enddo;
	for i = 75 to 78 do
		FieldsValues [ "F" + i ] = getLast ( "F" + i );
	enddo;
	for i = 80 to 85 do
		FieldsValues [ "F" + i ] = getLast ( "F" + i );
	enddo;
	
	~draw:
	
	area = getArea ();
	draw ();

EndProcedure

Procedure B45 ()

	result = get ( "F45" ) * get ( "A45" );

EndProcedure

Procedure D45 ()

	result = get ( "F45" ) * get ( "C45" );

EndProcedure

Procedure E45 ()

	result = get ( "B45" ) - get ( "D45" );

EndProcedure

//

Procedure B46 ()

	result = get ( "F46" ) * get ( "A46" );

EndProcedure

Procedure D46 ()

	result = get ( "F46" ) * get ( "C46" );

EndProcedure

Procedure E46 ()

	result = get ( "B46" ) - get ( "D46" );

EndProcedure

//

Procedure B52 ()

	result = get ( "F52" ) * get ( "A52" );

EndProcedure

Procedure D52 ()

	result = get ( "F52" ) * get ( "C52" );

EndProcedure

Procedure E52 ()

	result = get ( "B52" ) - get ( "D52" );

EndProcedure

//

Procedure B53 ()

	result = get ( "F53" ) * get ( "A53" );

EndProcedure

Procedure D53 ()

	result = get ( "F53" ) * get ( "C53" );

EndProcedure

Procedure E53 ()

	result = get ( "B53" ) - get ( "D53" );

EndProcedure

//

Procedure B54 ()

	result = get ( "F54" ) * get ( "A54" );

EndProcedure

Procedure D54 ()

	result = get ( "F54" ) * get ( "C54" );

EndProcedure

Procedure E54 ()

	result = get ( "B54" ) - get ( "D54" );

EndProcedure

//

Procedure B55 ()

	result = get ( "F55" ) * get ( "A55" );

EndProcedure

Procedure D55 ()

	result = get ( "F55" ) * get ( "C55" );

EndProcedure

Procedure E55 ()

	result = get ( "B55" ) - get ( "D55" );

EndProcedure

//

Procedure B56 ()

	result = get ( "F56" ) * get ( "A56" );

EndProcedure

Procedure D56 ()

	result = get ( "F56" ) * get ( "C56" );

EndProcedure

Procedure E56 ()

	result = get ( "B56" ) - get ( "D56" );

EndProcedure

//

Procedure B57 ()

	result = get ( "F57" ) * get ( "A57" );

EndProcedure

Procedure D57 ()

	result = get ( "F57" ) * get ( "C57" );

EndProcedure

Procedure E57 ()

	result = get ( "B57" ) - get ( "D57" );

EndProcedure

//

Procedure B66 ()

	result = get ( "F66" ) * get ( "A66" );

EndProcedure

Procedure D66 ()

	result = get ( "F66" ) * get ( "C66" );

EndProcedure

Procedure E66 ()

	result = get ( "B66" ) - get ( "D66" );

EndProcedure

///

Procedure B67 ()

	result = get ( "F67" ) * get ( "A67" );

EndProcedure

Procedure D67 ()

	result = get ( "F67" ) * get ( "C67" );

EndProcedure

Procedure E67 ()

	result = get ( "B67" ) - get ( "D67" );

EndProcedure

//

Procedure B68 ()

	result = get ( "F68" ) * get ( "A68" );

EndProcedure

Procedure D68 ()

	result = get ( "F68" ) * get ( "C68" );

EndProcedure

Procedure E68 ()

	result = get ( "B68" ) - get ( "D68" );

EndProcedure

//

Procedure B75 ()

	result = get ( "F75" ) * get ( "A75" );

EndProcedure

Procedure D75 ()

	result = get ( "F75" ) * get ( "C75" );

EndProcedure

Procedure E75 ()

	result = get ( "B75" ) - get ( "D75" );

EndProcedure

//

Procedure B76 ()

	result = get ( "F76" ) * get ( "A76" );

EndProcedure

Procedure D76 ()

	result = get ( "F76" ) * get ( "C76" );

EndProcedure

Procedure E76 ()

	result = get ( "B76" ) - get ( "D76" );

EndProcedure

//

Procedure B77 ()

	result = get ( "F77" ) * get ( "A77" );

EndProcedure

Procedure D77 ()

	result = get ( "F77" ) * get ( "C77" );

EndProcedure

Procedure E77 ()

	result = get ( "B77" ) - get ( "D77" );

EndProcedure

//

Procedure B78 ()

	result = get ( "F78" ) * get ( "A78" );

EndProcedure

Procedure D78 ()

	result = get ( "F78" ) * get ( "C78" );

EndProcedure

Procedure E78 ()

	result = get ( "B78" ) - get ( "D78" );

EndProcedure

//

Procedure B80 ()

	result = get ( "F80" ) * get ( "A80" );

EndProcedure

Procedure D80 ()

	result = get ( "F80" ) * get ( "C80" );

EndProcedure

Procedure E80 ()

	result = get ( "B80" ) - get ( "D80" );

EndProcedure

//

Procedure B81 ()

	result = get ( "F81" ) * get ( "A81" );

EndProcedure

Procedure D81 ()

	result = get ( "F81" ) * get ( "C81" );

EndProcedure

Procedure E81 ()

	result = get ( "B81" ) - get ( "D81" );

EndProcedure

//

Procedure B82 ()

	result = get ( "F82" ) * get ( "A82" );

EndProcedure

Procedure D82 ()

	result = get ( "F82" ) * get ( "C82" );

EndProcedure

Procedure E82 ()

	result = get ( "B82" ) - get ( "D82" );

EndProcedure

Procedure B83 ()

	result = get ( "F83" ) * get ( "A83" );

EndProcedure

Procedure D83 ()

	result = get ( "F83" ) * get ( "C83" );

EndProcedure

Procedure E83 ()

	result = get ( "B83" ) - get ( "D83" );

EndProcedure

Procedure B84 ()

	result = get ( "F84" ) * get ( "A84" );

EndProcedure

Procedure D84 ()

	result = get ( "F84" ) * get ( "C84" );

EndProcedure

Procedure E84 ()

	result = get ( "B84" ) - get ( "D84" );

EndProcedure

Procedure B85 ()

	result = get ( "F85" ) * get ( "A85" );

EndProcedure

Procedure D85 ()

	result = get ( "F85" ) * get ( "C85" );

EndProcedure

Procedure E85 ()

	result = get ( "B85" ) - get ( "D85" );

EndProcedure

Procedure A86 ()

	result = sum ( "A45:A46" ) + sum ( "A52:A57" ) + sum ( "A66:A68" ) + sum ( "A75:A78" ) + sum ( "A80:A85" );

EndProcedure

Procedure B86 ()

	result = sum ( "B45:B46" ) + sum ( "B52:B57" ) + sum ( "B66:B68" ) + sum ( "B75:B78" ) + sum ( "B80:B85" );

EndProcedure

Procedure C86 ()

	result = sum ( "C45:C46" ) + sum ( "C52:C57" ) + sum ( "C66:C68" ) + sum ( "C75:C78" ) + sum ( "C80:C85" );

EndProcedure

Procedure D86 ()

	result = sum ( "D45:D46" ) + sum ( "D52:D57" ) + sum ( "D66:D68" ) + sum ( "D75:D78" ) + sum ( "D80:D85" );

EndProcedure

Procedure E86 ()

	result = sum ( "E45:E46" ) + sum ( "E52:E57" ) + sum ( "E66:E68" ) + sum ( "E75:E78" ) + sum ( "E80:E85" );

EndProcedure
