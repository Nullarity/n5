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
	rowNumber = 94;
	rowNumber2 = 202;
	rowNumber3 = 116;
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
   		TabDoc.PageOrientation = PageOrientation.Landscape;
	endif;

EndProcedure

Procedure C30 ()

	result = get ( "A30" ) * get ( "B30" );

EndProcedure

Procedure E30 ()

	result = ( get ( "C30" ) - get ( "D30" ) ) * 0.15;

EndProcedure

Procedure F30 ()

	result = get ( "C30" ) - get ( "D30" ) - get ( "E30" );

EndProcedure

Procedure C31 ()

	result = get ( "A31" ) * get ( "B31" );

EndProcedure

Procedure F31 ()

	result = get ( "C31" ) - get ( "D31" );

EndProcedure

Procedure C32 ()

	result = get ( "A32" ) * get ( "B32" );

EndProcedure

Procedure E32 ()

	result = ( get ( "C32" ) - get ( "D32" ) ) * 0.15;

EndProcedure

Procedure F32 ()

	result = get ( "C32" ) - get ( "D32" ) - get ( "E32" );

EndProcedure

Procedure C33 ()

	result = get ( "A33" ) * get ( "B33" );

EndProcedure

Procedure E33 ()

	result = ( get ( "C33" ) - get ( "D33" ) ) * 0.15;

EndProcedure

Procedure F33 ()

	result = get ( "C33" ) - get ( "D33" ) - get ( "E33" );

EndProcedure

Procedure C34 ()

	result = get ( "A34" ) * get ( "B34" );

EndProcedure

Procedure F34 ()

	result = get ( "C34" ) - get ( "D34" );

EndProcedure

Procedure C35 ()

	result = get ( "A35" ) * get ( "B35" );

EndProcedure

Procedure E35 ()

	result = ( get ( "C35" ) - get ( "D35" ) ) * 0.15;

EndProcedure

Procedure F35 ()

	result = get ( "C35" ) - get ( "D35" ) - get ( "E35" );

EndProcedure

Procedure C36 ()

	result = get ( "A36" ) * get ( "B36" );

EndProcedure

Procedure E36 ()

	result = ( get ( "C36" ) - get ( "D36" ) ) * 0.15;

EndProcedure

Procedure F36 ()

	result = get ( "C36" ) - get ( "D36" ) - get ( "E36" );

EndProcedure

Procedure C37 ()

	result = get ( "A37" ) * get ( "B37" );

EndProcedure

Procedure F37 ()

	result = get ( "C37" ) - get ( "D37" );

EndProcedure

Procedure C38 ()

	result = get ( "A38" ) * get ( "B38" );

EndProcedure

Procedure E38 ()

	result = ( get ( "C38" ) - get ( "D38" ) ) * 0.15;

EndProcedure

Procedure F38 ()

	result = get ( "C38" ) - get ( "D38" ) - get ( "E38" );

EndProcedure

Procedure C39 ()

	result = get ( "A39" ) * get ( "B39" );

EndProcedure

Procedure E39 ()

	result = ( get ( "C39" ) - get ( "D39" ) ) * 0.15;

EndProcedure

Procedure F39 ()

	result = get ( "C39" ) - get ( "D39" ) - get ( "E39" );

EndProcedure

Procedure C40 ()

	result = get ( "A40" ) * get ( "B40" );

EndProcedure

Procedure E40 ()

	result = ( get ( "C40" ) - get ( "D40" ) ) * 0.15;

EndProcedure

Procedure F40 ()

	result = get ( "C40" ) - get ( "D40" ) - get ( "E40" );

EndProcedure

Procedure C41 ()

	result = get ( "A41" ) * get ( "B41" );

EndProcedure

Procedure F41 ()

	result = get ( "C41" ) - get ( "D41" );

EndProcedure

Procedure C42 ()

	result = get ( "A42" ) * get ( "B42" );

EndProcedure

Procedure E42 ()

	result = ( get ( "C42" ) - get ( "D42" ) ) * 0.15;

EndProcedure

Procedure F42 ()

	result = get ( "C42" ) - get ( "D42" ) - get ( "E42" );

EndProcedure

Procedure C43 ()

	result = get ( "A43" ) * get ( "B43" );

EndProcedure

Procedure E43 ()

	result = ( get ( "C43" ) - get ( "D43" ) ) * 0.15;

EndProcedure

Procedure F43 ()

	result = get ( "C43" ) - get ( "D43" ) - get ( "E43" );

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

Procedure E45 ()

	result = ( get ( "C45" ) - get ( "D45" ) ) * 0.15;

EndProcedure

Procedure F45 ()

	result = get ( "C45" ) - get ( "D45" ) - get ( "E45" );

EndProcedure

Procedure A47 ()

	result = get ( "A30" ) + get ( "A33" ) + get ( "A36" ) + get ( "A43" );

EndProcedure

Procedure C47 ()

	result = get ( "C30" ) + get ( "C33" ) + get ( "C36" ) + get ( "C43" );

EndProcedure

Procedure D47 ()

	result = get ( "D30" ) + get ( "D33" ) + get ( "D36" ) + get ( "D43" );

EndProcedure

Procedure E47 ()

	result = get ( "E30" ) + get ( "E33" ) + get ( "E36" ) + get ( "E43" );

EndProcedure

Procedure F47 ()

	result = get ( "F30" ) + get ( "F33" ) + get ( "F36" ) + get ( "F43" );

EndProcedure

Procedure F49 ()

	result = get ( "F31" ) + get ( "F34" ) + get ( "F37" ) + get ( "F44" );

EndProcedure

Procedure A49 ()

	result = get ( "A31" ) + get ( "A34" ) + get ( "A37" ) + get ( "A44" );

EndProcedure

Procedure C49 ()

	result = get ( "C31" ) + get ( "C34" ) + get ( "C37" ) + get ( "C44" );

EndProcedure

Procedure D49 ()

	result = get ( "D31" ) + get ( "D34" ) + get ( "D37" ) + get ( "D44" );

EndProcedure

Procedure A50 ()

	result = get ( "A32" ) + get ( "A35" ) + get ( "A38" ) + get ( "A45" );

EndProcedure

Procedure C50 ()

	result = get ( "C32" ) + get ( "C35" ) + get ( "C38" ) + get ( "C45" );

EndProcedure

Procedure D50 ()

	result = get ( "D32" ) + get ( "D35" ) + get ( "D38" ) + get ( "D45" );

EndProcedure

Procedure E50 ()

	result = get ( "E32" ) + get ( "E35" ) + get ( "E38" ) + get ( "E45" );

EndProcedure

Procedure F50 ()

	result = get ( "F32" ) + get ( "F35" ) + get ( "F38" ) + get ( "F45" );

EndProcedure

Procedure C51 ()

	result = sum ( "C30:C45" );

EndProcedure

Procedure D51 ()

	result = sum ( "D30:D45" );

EndProcedure

Procedure E51 ()

	result = get ( "E39" ) + get ( "E47" ) + get ( "E40" ) + get ( "E50" );

EndProcedure

Procedure F51 ()

	result = sum ( "F30:F45" );

EndProcedure

Procedure D104 ()

	result = sum ( "D94:D103" );

EndProcedure

Procedure E104 ()

	result = sum ( "E94:E103" );

EndProcedure

Procedure F104 ()

	result = sum ( "F94:F103" );

EndProcedure

Procedure G104 ()

	result = sum ( "G94:G103" );

EndProcedure

Procedure H104 ()

	result = sum ( "H94:H103" );

EndProcedure

Procedure I104 ()

	result = sum ( "I94:I103" );

EndProcedure

Procedure J104 ()

	result = sum ( "J94:J103" );

EndProcedure

Procedure K104 ()

	result = sum ( "K94:K103" );

EndProcedure

Procedure L104 ()

	result = sum ( "L94:L103" );

EndProcedure

Procedure M104 ()

	result = sum ( "M94:M103" );

EndProcedure

Procedure N104 ()

	result = sum ( "N94:N103" );

EndProcedure

Procedure O104 ()

	result = sum ( "O94:O103" );

EndProcedure

Procedure P104 ()

	result = sum ( "P94:P103" );

EndProcedure

Procedure Q104 ()

	result = sum ( "Q94:Q103" );

EndProcedure

Procedure R104 ()

	result = sum ( "R94:R103" );

EndProcedure

Procedure S104 ()

	result = sum ( "S94:S103" );

EndProcedure

Procedure B126 ()

	result = sum ( "B116:B125" );

EndProcedure

Procedure C126 ()

	result = sum ( "C116:C125" );

EndProcedure

Procedure D126 ()

	result = sum ( "D116:D125" );

EndProcedure

Procedure E126 ()

	result = sum ( "E116:E125" );

EndProcedure

Procedure F126 ()

	result = sum ( "F116:F125" );

EndProcedure

Procedure G126 ()

	result = sum ( "G116:G125" );

EndProcedure

Procedure H126 ()

	result = sum ( "H116:H125" );

EndProcedure

Procedure I126 ()

	result = sum ( "I116:I125" );

EndProcedure

Procedure J126 ()

	result = sum ( "J116:J125" );

EndProcedure

Procedure K126 ()

	result = sum ( "K116:K125" );

EndProcedure

Procedure L126 ()

	result = sum ( "L116:L125" );

EndProcedure

Procedure M126 ()

	result = sum ( "M116:M125" );

EndProcedure

Procedure N126 ()

	result = sum ( "N116:N125" );

EndProcedure

Procedure O126 ()

	result = sum ( "O116:O125" );

EndProcedure

Procedure P126 ()

	result = sum ( "P116:P125" );

EndProcedure

Procedure Q126 ()

	result = sum ( "Q116:Q125" );

EndProcedure

Procedure B151 ()

	result = sum ( "B141:B150" );

EndProcedure

Procedure C151 ()

	result = sum ( "C141:C150" );

EndProcedure

Procedure D151 ()

	result = sum ( "D141:D150" );

EndProcedure

Procedure E151 ()

	result = sum ( "E141:E150" );

EndProcedure

Procedure F151 ()

	result = sum ( "F141:F150" );

EndProcedure

Procedure G151 ()

	result = sum ( "G141:G150" );

EndProcedure

Procedure H151 ()

	result = sum ( "H141:H150" );

EndProcedure

Procedure I151 ()

	result = sum ( "I141:I150" );

EndProcedure

Procedure J151 ()

	result = sum ( "J141:J150" );

EndProcedure

Procedure K151 ()

	result = sum ( "K141:K150" );

EndProcedure

Procedure L151 ()

	result = sum ( "L141:L150" );

EndProcedure

Procedure M151 ()

	result = sum ( "M141:M150" );

EndProcedure

Procedure N151 ()

	result = sum ( "N141:N150" );

EndProcedure

Procedure O151 ()

	result = sum ( "O141:O150" );

EndProcedure

Procedure P151 ()

	result = sum ( "P141:P150" );

EndProcedure

Procedure Q151 ()

	result = sum ( "Q141:Q150" );

EndProcedure

Procedure R151 ()

	result = sum ( "R141:R150" );

EndProcedure

Procedure S151 ()

	result = sum ( "S141:S150" );

EndProcedure

Procedure T151 ()

	result = sum ( "T141:T150" );

EndProcedure

Procedure U151 ()

	result = sum ( "U141:U150" );

EndProcedure

Procedure V151 ()

	result = sum ( "V141:V150" );

EndProcedure

Procedure W151 ()

	result = sum ( "W141:W150" );

EndProcedure

Procedure X151 ()

	result = sum ( "X141:X150" );

EndProcedure

Procedure Y151 ()

	result = sum ( "Y141:Y150" );

EndProcedure

Procedure Z151 ()

	result = sum ( "Z141:Z150" );

EndProcedure

Procedure AA151 ()

     result = get ( "AA141" ) + get ( "AA142" ) + get ( "AA143" ) + get ( "AA144" ) + get ( "AA145" ) + get ( "AA146" ) + get ( "AA147" ) + get ( "AA148" ) + get ( "AA149" ) + get ( "AA150" );

EndProcedure

Procedure AB151 ()

     result = get ( "AB141" ) + get ( "AB142" ) + get ( "AB143" ) + get ( "AB144" ) + get ( "AB145" ) + get ( "AB146" ) + get ( "AB147" ) + get ( "AB148" ) + get ( "AB149" ) + get ( "AB150" );

EndProcedure

Procedure AC151 ()

     result = get ( "AC141" ) + get ( "AC142" ) + get ( "AC143" ) + get ( "AC144" ) + get ( "AC145" ) + get ( "AC146" ) + get ( "AC147" ) + get ( "AC148" ) + get ( "AC149" ) + get ( "AC150" );

EndProcedure

Procedure AD151 ()

     result = get ( "AD141" ) + get ( "AD142" ) + get ( "AD143" ) + get ( "AD144" ) + get ( "AD145" ) + get ( "AD146" ) + get ( "AD147" ) + get ( "AD148" ) + get ( "AD149" ) + get ( "AD150" );

EndProcedure

Procedure AE151 ()

     result = get ( "AE141" ) + get ( "AE142" ) + get ( "AE143" ) + get ( "AE144" ) + get ( "AE145" ) + get ( "AE146" ) + get ( "AE147" ) + get ( "AE148" ) + get ( "AE149" ) + get ( "AE150" );

EndProcedure

Procedure AF151 ()

     result = get ( "AF141" ) + get ( "AF142" ) + get ( "AF143" ) + get ( "AF144" ) + get ( "AF145" ) + get ( "AF146" ) + get ( "AF147" ) + get ( "AF148" ) + get ( "AF149" ) + get ( "AF150" );

EndProcedure

Procedure AG151 ()

     result = get ( "AG141" ) + get ( "AG142" ) + get ( "AG143" ) + get ( "AG144" ) + get ( "AG145" ) + get ( "AG146" ) + get ( "AG147" ) + get ( "AG148" ) + get ( "AG149" ) + get ( "AG150" );

EndProcedure



Procedure B174 ()

	result = sum ( "B164:B173" );

EndProcedure

Procedure C174 ()

	result = sum ( "C164:C173" );

EndProcedure

Procedure D174 ()

	result = sum ( "D164:D173" );

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

Procedure R164 ()

	result = get ( "B164" ) + get ( "C164" ) + get ( "D164" ) + get ( "E164" ) + get ( "F164" ) + get ( "G164" ) + get ( "H164" ) + get ( "I164" ) +
	get ( "J164" ) + get ( "K164" ) + get ( "L164" ) + get ( "M164" ) + get ( "N164" ) + get ( "O164" ) + get ( "O164" ) + get ( "Q164" );

EndProcedure
Procedure R165 ()

	result = get ( "B165" ) + get ( "C165" ) + get ( "D165" ) + get ( "E165" ) + get ( "F165" ) + get ( "G165" ) + get ( "H165" ) + get ( "I165" ) +
	get ( "J165" ) + get ( "K165" ) + get ( "L165" ) + get ( "M165" ) + get ( "N165" ) + get ( "O165" ) + get ( "O165" ) + get ( "Q165" );

EndProcedure

Procedure R166 ()

	result = get ( "B166" ) + get ( "C166" ) + get ( "D166" ) + get ( "E166" ) + get ( "F166" ) + get ( "G166" ) + get ( "H166" ) + get ( "I166" ) +
	get ( "J166" ) + get ( "K166" ) + get ( "L166" ) + get ( "M166" ) + get ( "N166" ) + get ( "O166" ) + get ( "O166" ) + get ( "Q166" );

EndProcedure

Procedure R167 ()

	result = get ( "B167" ) + get ( "C167" ) + get ( "D167" ) + get ( "E167" ) + get ( "F167" ) + get ( "G167" ) + get ( "H167" ) + get ( "I167" ) +
	get ( "J167" ) + get ( "K167" ) + get ( "L167" ) + get ( "M167" ) + get ( "N167" ) + get ( "O167" ) + get ( "O167" ) + get ( "Q167" );

EndProcedure

Procedure R168 ()

	result = get ( "B168" ) + get ( "C168" ) + get ( "D168" ) + get ( "E168" ) + get ( "F168" ) + get ( "G168" ) + get ( "H168" ) + get ( "I168" ) +
	get ( "J168" ) + get ( "K168" ) + get ( "L168" ) + get ( "M168" ) + get ( "N168" ) + get ( "O168" ) + get ( "O168" ) + get ( "Q168" );

EndProcedure

Procedure R169 ()

	result = get ( "B169" ) + get ( "C169" ) + get ( "D169" ) + get ( "E169" ) + get ( "F169" ) + get ( "G169" ) + get ( "H169" ) + get ( "I169" ) +
	get ( "J169" ) + get ( "K169" ) + get ( "L169" ) + get ( "M169" ) + get ( "N169" ) + get ( "O169" ) + get ( "O169" ) + get ( "Q169" );

EndProcedure

Procedure R170 ()

	result = get ( "B170" ) + get ( "C170" ) + get ( "D170" ) + get ( "E170" ) + get ( "F170" ) + get ( "G170" ) + get ( "H170" ) + get ( "I170" ) +
	get ( "J170" ) + get ( "K170" ) + get ( "L170" ) + get ( "M170" ) + get ( "N170" ) + get ( "O170" ) + get ( "O170" ) + get ( "Q170" );

EndProcedure

Procedure R171 ()

	result = get ( "B171" ) + get ( "C171" ) + get ( "D171" ) + get ( "E171" ) + get ( "F171" ) + get ( "G171" ) + get ( "H171" ) + get ( "I171" ) +
	get ( "J171" ) + get ( "K171" ) + get ( "L171" ) + get ( "M171" ) + get ( "N171" ) + get ( "O171" ) + get ( "O171" ) + get ( "Q171" );

EndProcedure

Procedure R172 ()

	result = get ( "B172" ) + get ( "C172" ) + get ( "D172" ) + get ( "E172" ) + get ( "F172" ) + get ( "G172" ) + get ( "H172" ) + get ( "I172" ) +
	get ( "J172" ) + get ( "K172" ) + get ( "L172" ) + get ( "M172" ) + get ( "N172" ) + get ( "O172" ) + get ( "O172" ) + get ( "Q172" );

EndProcedure

Procedure R173 ()

	result = get ( "B173" ) + get ( "C173" ) + get ( "D173" ) + get ( "E173" ) + get ( "F173" ) + get ( "G173" ) + get ( "H173" ) + get ( "I173" ) +
	get ( "J173" ) + get ( "K173" ) + get ( "L173" ) + get ( "M173" ) + get ( "N173" ) + get ( "O173" ) + get ( "O173" ) + get ( "Q173" );

EndProcedure


Procedure E208 ()

	result = sum ( "E202:E207" );

EndProcedure

Procedure F208 ()

	result = sum ( "F202:F207" );

EndProcedure
Procedure G208 ()

	result = sum ( "G202:G207" );

EndProcedure

Procedure H208 ()

	result = sum ( "H202:H207" );

EndProcedure

Procedure I208 ()

	result = sum ( "I202:I207" );

EndProcedure

Procedure J208 ()

	result = sum ( "J202:J207" );

EndProcedure

Procedure K208 ()

	result = sum ( "K202:K207" );

EndProcedure

Procedure L208 ()

	result = sum ( "L202:L207" );

EndProcedure

Procedure M208 ()

	result = sum ( "M202:M207" );

EndProcedure

Procedure N208 ()

	result = sum ( "N202:N207" );

EndProcedure

Procedure O208 ()

	result = sum ( "O202:O207" );

EndProcedure

Procedure P208 ()

	result = sum ( "P202:P207" );

EndProcedure

Procedure Q208 ()

	result = sum ( "Q202:Q207" );

EndProcedure

Procedure R208 ()

	result = sum ( "R202:R207" );

EndProcedure

Procedure S208 ()

	result = sum ( "S202:S207" );

EndProcedure

Procedure T208 ()

	result = sum ( "T202:T207" );

EndProcedure

Procedure U208 ()

	result = sum ( "U202:U207" );

EndProcedure

Procedure V208 ()

	result = sum ( "V202:V207" );

EndProcedure

Procedure W208 ()

	result = sum ( "W202:W207" );

EndProcedure

Procedure X208 ()

	result = sum ( "X202:X207" );

EndProcedure

Procedure X202 ()

	result = get ( "E202" ) + get ( "F202" ) + get ( "G202" ) + 
	get ( "K202" ) + get ( "L202" ) + get ( "M202" ) + get ( "N202" ) + get ( "O202" ) + get ( "P202" ) + get ( "Q202" ) +
	get ( "R202" ) + get ( "S202" ) + get ( "T202" ) + get ( "U202" ) + get ( "V202" ) + get ( "W202" );

EndProcedure

Procedure X203 ()

	result = get ( "E203" ) + get ( "F203" ) + get ( "G203" ) + 
	get ( "K203" ) + get ( "L203" ) + get ( "M203" ) + get ( "N203" ) + get ( "O203" ) + get ( "P203" ) + get ( "Q203" ) +
	get ( "R203" ) + get ( "S203" ) + get ( "T203" ) + get ( "U203" ) + get ( "V203" ) + get ( "W203" );

EndProcedure

Procedure X204 ()

	result = get ( "E204" ) + get ( "F204" ) + get ( "G204" ) + 
	get ( "K204" ) + get ( "L204" ) + get ( "M204" ) + get ( "N204" ) + get ( "O204" ) + get ( "P204" ) + get ( "Q204" ) +
	get ( "R204" ) + get ( "S204" ) + get ( "T204" ) + get ( "U204" ) + get ( "V204" ) + get ( "W204" );

EndProcedure

Procedure X205 ()

	result = get ( "E205" ) + get ( "F205" ) + get ( "G205" ) + 
	get ( "K205" ) + get ( "L205" ) + get ( "M205" ) + get ( "N205" ) + get ( "O205" ) + get ( "P205" ) + get ( "Q205" ) +
	get ( "R205" ) + get ( "S205" ) + get ( "T205" ) + get ( "U205" ) + get ( "V205" ) + get ( "W205" );

EndProcedure

Procedure X206 ()

	result = get ( "E206" ) + get ( "F206" ) + get ( "G206" ) + 
	get ( "K206" ) + get ( "L206" ) + get ( "M206" ) + get ( "N206" ) + get ( "O206" ) + get ( "P206" ) + get ( "Q206" ) +
	get ( "R206" ) + get ( "S206" ) + get ( "T206" ) + get ( "U206" ) + get ( "V206" ) + get ( "W206" );

EndProcedure

Procedure X207 ()

	result = get ( "E207" ) + get ( "F207" ) + get ( "G207" ) + 
	get ( "K207" ) + get ( "L207" ) + get ( "M207" ) + get ( "N207" ) + get ( "O207" ) + get ( "P207" ) + get ( "Q207" ) +
	get ( "R207" ) + get ( "S207" ) + get ( "T207" ) + get ( "U207" ) + get ( "V207" ) + get ( "W207" );

EndProcedure