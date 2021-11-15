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
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	
	FieldsValues [ "Period" ] = "A/" + Format ( DateEnd, "DF='yyyy'" );
	
	// Table
	line = 1;
	rowNumber = 164;
	rowNumber2 = 77;
	for each row in Env.Divisions do
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = row.Code;
		FieldsValues [ "C" + rowNumber ] = row.Cutam;
		rowNumber = rowNumber + 1;
		FieldsValues [ "A" + rowNumber2 ] = line;
		FieldsValues [ "B" + rowNumber2 ] = row.Code;
		FieldsValues [ "C" + rowNumber2 ] = row.Cutam;
		rowNumber2 = rowNumber2 + 1;
		line = line + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	draw ();
	
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   	endif;

EndProcedure

Procedure F28 ()

	result = get ( "C28" ) - get ( "D28" ) - get ( "E28" );

EndProcedure
Procedure F29 ()

	result = get ( "C29" ) - get ( "D29" ) - get ( "E29" );

EndProcedure

Procedure F30 ()

	result = get ( "C30" ) - get ( "D30" ) - get ( "E30" );

EndProcedure

Procedure F31 ()

	result = get ( "C31" ) - get ( "D31" ) - get ( "E31" );

EndProcedure

Procedure F32 ()

	result = get ( "C32" ) - get ( "D32" ) - get ( "E32" );

EndProcedure

Procedure F33 ()

	result = get ( "C33" ) - get ( "D33" ) - get ( "E33" );

EndProcedure

Procedure F34 ()

	result = get ( "C34" ) - get ( "D34" ) - get ( "E34" );

EndProcedure

Procedure A35 ()

	result = sum ( "A28:A34" );

EndProcedure

Procedure C35 ()

	result = sum ( "C28:C34" );

EndProcedure

Procedure D35 ()

	result = sum ( "D28:D34" );

EndProcedure

Procedure E35 ()

	result = sum ( "E28:E34" );

EndProcedure

Procedure F35 ()

	result = sum ( "F28:F34" );

EndProcedure

Procedure D97 ()

	result = sum ( "D77:D96" );

EndProcedure

Procedure E97 ()

	result = sum ( "E77:E96" );

EndProcedure

Procedure F97 ()

	result = sum ( "F77:F96" );

EndProcedure

Procedure G97 ()

	result = sum ( "G77:G96" );

EndProcedure

Procedure H97 ()

	result = sum ( "H77:H96" );

EndProcedure

Procedure I97 ()

	result = sum ( "I77:I96" );

EndProcedure

Procedure J97 ()

	result = sum ( "J77:J96" );

EndProcedure

Procedure R97 ()

	result = sum ( "R77:R96" );

EndProcedure

Procedure S97 ()

	result = sum ( "S77:S96" );

EndProcedure

Procedure T97 ()

	result = sum ( "T77:T96" );

EndProcedure

Procedure U97 ()

	result = sum ( "U77:U96" );

EndProcedure

Procedure V97 ()

	result = sum ( "V77:V96" );

EndProcedure

Procedure W97 ()

	result = sum ( "W77:W96" );

EndProcedure

Procedure X97 ()

	result = sum ( "X77:X96" );

EndProcedure

Procedure B139 ()

	result = sum ( "B119:B138" );

EndProcedure

Procedure C139 ()

	result = sum ( "C119:C138" );

EndProcedure

Procedure D139 ()

	result = sum ( "D119:D138" );

EndProcedure

Procedure E139 ()

	result = sum ( "E119:E138" );

EndProcedure

Procedure F139 ()

	result = sum ( "F119:F138" );

EndProcedure

Procedure G139 ()

	result = sum ( "G119:G138" );

EndProcedure

Procedure H139 ()

	result = sum ( "H119:H138" );

EndProcedure

Procedure I139 ()

	result = sum ( "I119:I138" );

EndProcedure

Procedure J139 ()

	result = sum ( "J119:J138" );

EndProcedure

Procedure K139 ()

	result = sum ( "K119:K138" );

EndProcedure

Procedure L139 ()

	result = sum ( "L119:L138" );

EndProcedure

Procedure M139 ()

	result = sum ( "M119:M138" );

EndProcedure

Procedure N139 ()

	result = sum ( "N119:N138" );

EndProcedure

Procedure O139 ()

	result = sum ( "O119:O138" );

EndProcedure

Procedure P139 ()

	result = sum ( "P119:P138" );

EndProcedure

Procedure Q139 ()

	result = sum ( "Q119:Q138" );

EndProcedure

Procedure R139 ()

	result = sum ( "R119:R138" );

EndProcedure

Procedure S139 ()

	result = sum ( "S119:S138" );

EndProcedure

Procedure T139 ()

	result = sum ( "T119:T138" );

EndProcedure

Procedure U139 ()

	result = sum ( "U119:U138" );

EndProcedure

Procedure V139 ()

	result = sum ( "V119:V138" );

EndProcedure

Procedure W139 ()

	result = sum ( "W119:W138" );

EndProcedure

Procedure W119 ()

	result = sum ( "P119:V119" );

EndProcedure

Procedure W120 ()

	result = sum ( "P120:V120" );

EndProcedure

Procedure W121 ()

	result = sum ( "P121:V121" );

EndProcedure

Procedure W122 ()

	result = sum ( "P122:V122" );

EndProcedure

Procedure W123 ()

	result = sum ( "P123:V123" );

EndProcedure

Procedure W124 ()

	result = sum ( "P124:V124" );

EndProcedure

Procedure W125 ()

	result = sum ( "P125:V125" );

EndProcedure

Procedure W126 ()

	result = sum ( "P126:V126" );

EndProcedure

Procedure W127 ()

	result = sum ( "P127:V127" );

EndProcedure

Procedure W128 ()

	result = sum ( "P128:V128" );

EndProcedure

Procedure W129 ()

	result = sum ( "P129:V129" );

EndProcedure

Procedure W130 ()

	result = sum ( "P130:V130" );

EndProcedure

Procedure W131 ()

	result = sum ( "P131:V131" );

EndProcedure

Procedure W132 ()

	result = sum ( "P132:V132" );

EndProcedure

Procedure W133 ()

	result = sum ( "P133:V133" );

EndProcedure

Procedure W134 ()

	result = sum ( "P134:V134" );

EndProcedure

Procedure W135 ()

	result = sum ( "P135:V135" );

EndProcedure

Procedure W136 ()

	result = sum ( "P136:V136" );

EndProcedure

Procedure W137 ()

	result = sum ( "P137:V137" );

EndProcedure

Procedure W138 ()

	result = sum ( "P138:V138" );

EndProcedure

Procedure E174 ()

	result = sum ( "E164:E173" );

EndProcedure

Procedure F174 ()

	result = sum ( "F164:F173" );

EndProcedure

Procedure G174 ()

	result = sum ( "G164:G173" );

EndProcedure

Procedure H174 ()

	result = sum ( "H164:H173" );

EndProcedure

Procedure I174 ()

	result = sum ( "I164:I173" );

EndProcedure

Procedure J174 ()

	result = sum ( "J164:J173" );

EndProcedure

Procedure K174 ()

	result = sum ( "K164:K173" );

EndProcedure

Procedure L174 ()

	result = sum ( "L164:L173" );

EndProcedure

Procedure M174 ()

	result = sum ( "M164:M173" );

EndProcedure

Procedure N174 ()

	result = sum ( "N164:N173" );

EndProcedure

Procedure O174 ()

	result = sum ( "O164:O173" );

EndProcedure

Procedure P174 ()

	result = sum ( "P164:P173" );

EndProcedure

Procedure Q174 ()

	result = sum ( "Q164:Q173" );

EndProcedure

Procedure R174 ()

	result = sum ( "R164:R173" );

EndProcedure

Procedure C191 ()

	result = sum ( "C186:C190" );

EndProcedure

Procedure D191 ()

	result = sum ( "D186:D190" );

EndProcedure

Procedure E191 ()

	result = sum ( "E186:E190" );

EndProcedure

Procedure F191 ()

	result = sum ( "F186:F190" );

EndProcedure

Procedure G191 ()

	result = sum ( "G186:G190" );

EndProcedure

Procedure H191 ()

	result = sum ( "H186:H190" );

EndProcedure

Procedure I191 ()

	result = sum ( "I186:I190" );

EndProcedure

Procedure J191 ()

	result = sum ( "J186:J190" );

EndProcedure

Procedure K191 ()

	result = sum ( "K186:K190" );

EndProcedure

Procedure L191 ()

	result = sum ( "L186:L190" );

EndProcedure

Procedure M191 ()

	result = sum ( "M186:M190" );

EndProcedure

Procedure N191 ()

	result = sum ( "N186:N190" );

EndProcedure

Procedure O191 ()

	result = sum ( "O186:O190" );

EndProcedure

Procedure P191 ()

	result = sum ( "P186:P190" );

EndProcedure 