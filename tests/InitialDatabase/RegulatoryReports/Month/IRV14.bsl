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
	|;
	|// Income
	|select sum ( Turnovers.AmountTurnoverCr ) as Amount, Turnovers.BalancedAccount as Account, Turnovers.ExtDimension1 as Code, Turnovers.Recorder as Recorder
	|into Income
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account.Code = ""5343"", , Company = &Company
	|			and ExtDimension1 <> value ( Enum.IncomeCodes.EmptyRef ), ,  ) as Turnovers
	|group by Turnovers.BalancedAccount, Turnovers.ExtDimension1, Turnovers.Recorder
	|;
	|// Base
	|select sum ( Turnovers.AmountTurnoverDr ) as Amount, Income.Code as Code
	|into Base
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, Recorder, Account in ( select Account from Income ), , Company = &Company, ,  ) as Turnovers
	|	// 
	|	// Income
	|	// 
	|	left join Income as Income
	|	on Income.Recorder = Turnovers.Recorder
	|where Turnovers.Recorder in ( select Recorder from Income )
	|group by Income.Code 
	|;
	|// #Table
	|select Income.Amount as IncomeAmount, presentation ( Income.Code ) as Code, Base.Amount as BaseAmount,
	|	case when Income.Code = value ( Enum.IncomeCodes.DOB ) then ""38""
	|		when Income.Code = value ( Enum.IncomeCodes.SER ) then ""39""
	|		when Income.Code = value ( Enum.IncomeCodes.FOL ) then ""40""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVA ) then ""41""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSA ) then ""42""
	|		when Income.Code = value ( Enum.IncomeCodes.ROY ) then ""43""
	|		when Income.Code = value ( Enum.IncomeCodes.NOR ) then ""44""
	|		when Income.Code = value ( Enum.IncomeCodes.PUB ) then ""45""
	|		when Income.Code = value ( Enum.IncomeCodes.LIV ) then ""46""
	|		when Income.Code = value ( Enum.IncomeCodes.PLT ) then ""47""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVB ) then ""48""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSB ) then ""49""
	|		else ""50""
	|	end as Row
	|from ( select sum ( Income.Amount ) as Amount, Income.Code as Code
	|		from Income as Income
	|		group by Income.Code
	|	  ) as Income
	|	// 
	|	// Base
	|	// 
	|	left join Base as Base
	|	on Base.Code = Income.Code
	|;
	|// Compensations
	|select Compensations.Account as Account, Compensations.Ref as Salary
	|into Compensations
	|from ChartOfCalculationTypes.Compensations as Compensations
	|where Compensations.Method in ( value ( Enum.Calculations.HourlyRate ), value ( Enum.Calculations.MonthlyRate ) )
	|and not Compensations.DeletionMark
	|;
	|// #Salary
	|select ""SalaryPayed"" as Key, Turnovers.AmountTurnoverDr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , Account in ( select Account from Compensations ), , Company = &Company
	|							and ExtDimension2 in ( select Salary from Compensations ), ) as Turnovers
	|;
	|// #IncomeTax
	|select ""IncomeTax"" as Key, Turnovers.AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , 
	|		Account in ( 
	|			select Taxes.Account as Account
	|			from ChartOfCalculationTypes.Taxes as Taxes
	|			where Taxes.Method = value ( Enum.Calculations.IncomeTax ) or Taxes.Method = value ( Enum.Calculations.FixedIncomeTax )
	|			and not Taxes.DeletionMark 
	|					), , 
	|		Company = &Company, 
	|		BalancedAccount in ( select Account from Compensations ),  ) as Turnovers
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
	
	FieldsValues [ "Period" ] = "L/" + Format ( DateEnd, "DF='MM/yyyy'" );
	
	// DefaultValues
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	
	// Table
	line = 1;
	rowNumber = 99;
	for each row in Env.Divisions do
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = row.Code;
		FieldsValues [ "C" + rowNumber ] = row.Cutam;
		rowNumber = rowNumber + 1;
		line = line + 1;
	enddo;
	
	//	******************
	//	Codes
	//  ******************
	
	// Salary
	assignField ( "A36", "SalaryPayed", "Salary" );
	assignField ( "B36", "IncomeTax", "IncomeTax" );
	
	for each row in Env.Table do
		FieldsValues [ "A" + row.Row ] = row.BaseAmount;
		FieldsValues [ "B" + row.Row ] = row.IncomeAmount;
	enddo;
	
	~draw:
		
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
   	endif;

EndProcedure

Procedure S99 ()

	result = get ( "D99" ) + get ( "E99" ) + get ( "F99" ) + get ( "G99" ) + get ( "H99" ) + get ( "I99" ) + get ( "J99" ) + 
	get ( "K99" ) + get ( "L99" ) + get ( "M99" ) + get ( "N99" ) + get ( "O99" ) + get ( "P99" ) + get ( "Q99" ) + get ( "R99" );

EndProcedure

Procedure S100 ()

	result = get ( "D100" ) + get ( "E100" ) + get ( "F100" ) + get ( "G100" ) + get ( "H100" ) + get ( "I100" ) + get ( "J100" ) + 
	get ( "K100" ) + get ( "L100" ) + get ( "M100" ) + get ( "N100" ) + get ( "O100" ) + get ( "P100" ) + get ( "Q100" ) + get ( "R100" );

EndProcedure

Procedure S101 ()

	result = get ( "D101" ) + get ( "E101" ) + get ( "F101" ) + get ( "G101" ) + get ( "H101" ) + get ( "I101" ) + get ( "J101" ) + 
	get ( "K101" ) + get ( "L101" ) + get ( "M101" ) + get ( "N101" ) + get ( "O101" ) + get ( "P101" ) + get ( "Q101" ) + get ( "R101" );

EndProcedure

Procedure S102 ()

	result = get ( "D102" ) + get ( "E102" ) + get ( "F102" ) + get ( "G102" ) + get ( "H102" ) + get ( "I102" ) + get ( "J102" ) + 
	get ( "K102" ) + get ( "L102" ) + get ( "M102" ) + get ( "N102" ) + get ( "O102" ) + get ( "P102" ) + get ( "Q102" ) + get ( "R102" );

EndProcedure

Procedure S103 ()

	result = get ( "D103" ) + get ( "E103" ) + get ( "F103" ) + get ( "G103" ) + get ( "H103" ) + get ( "I103" ) + get ( "J103" ) + 
	get ( "K103" ) + get ( "L103" ) + get ( "M103" ) + get ( "N103" ) + get ( "O103" ) + get ( "P103" ) + get ( "Q103" ) + get ( "R103" );

EndProcedure

Procedure S104 ()

	result = get ( "D104" ) + get ( "E104" ) + get ( "F104" ) + get ( "G104" ) + get ( "H104" ) + get ( "I104" ) + get ( "J104" ) + 
	get ( "K104" ) + get ( "L104" ) + get ( "M104" ) + get ( "N104" ) + get ( "O104" ) + get ( "P104" ) + get ( "Q104" ) + get ( "R104" );

EndProcedure

Procedure S105 ()

	result = get ( "D105" ) + get ( "E105" ) + get ( "F105" ) + get ( "G105" ) + get ( "H105" ) + get ( "I105" ) + get ( "J105" ) + 
	get ( "K105" ) + get ( "L105" ) + get ( "M105" ) + get ( "N105" ) + get ( "O105" ) + get ( "P105" ) + get ( "Q105" ) + get ( "R105" );

EndProcedure

Procedure S106 ()

	result = get ( "D106" ) + get ( "E106" ) + get ( "F106" ) + get ( "G106" ) + get ( "H106" ) + get ( "I106" ) + get ( "J106" ) + 
	get ( "K106" ) + get ( "L106" ) + get ( "M106" ) + get ( "N106" ) + get ( "O106" ) + get ( "P106" ) + get ( "Q106" ) + get ( "R106" );

EndProcedure

Procedure S107 ()

	result = get ( "D107" ) + get ( "E107" ) + get ( "F107" ) + get ( "G107" ) + get ( "H107" ) + get ( "I107" ) + get ( "J107" ) + 
	get ( "K107" ) + get ( "L107" ) + get ( "M107" ) + get ( "N107" ) + get ( "O107" ) + get ( "P107" ) + get ( "Q107" ) + get ( "R107" );

EndProcedure

Procedure S108 ()

	result = get ( "D108" ) + get ( "E108" ) + get ( "F108" ) + get ( "G108" ) + get ( "H108" ) + get ( "I108" ) + get ( "J108" ) + 
	get ( "K108" ) + get ( "L108" ) + get ( "M108" ) + get ( "N108" ) + get ( "O108" ) + get ( "P108" ) + get ( "Q108" ) + get ( "R108" );

EndProcedure

Procedure S109 ()

	result = get ( "D109" ) + get ( "E109" ) + get ( "F109" ) + get ( "G109" ) + get ( "H109" ) + get ( "I109" ) + get ( "J109" ) + 
	get ( "K109" ) + get ( "L109" ) + get ( "M109" ) + get ( "N109" ) + get ( "O109" ) + get ( "P109" ) + get ( "Q109" ) + get ( "R109" );

EndProcedure

Procedure S110 ()

	result = get ( "D110" ) + get ( "E110" ) + get ( "F110" ) + get ( "G110" ) + get ( "H110" ) + get ( "I110" ) + get ( "J110" ) + 
	get ( "K110" ) + get ( "L110" ) + get ( "M110" ) + get ( "N110" ) + get ( "O110" ) + get ( "P110" ) + get ( "Q110" ) + get ( "R110" );

EndProcedure

Procedure S111 ()

	result = get ( "D111" ) + get ( "E111" ) + get ( "F111" ) + get ( "G111" ) + get ( "H111" ) + get ( "I111" ) + get ( "J111" ) + 
	get ( "K111" ) + get ( "L111" ) + get ( "M111" ) + get ( "N111" ) + get ( "O111" ) + get ( "P111" ) + get ( "Q111" ) + get ( "R111" );

EndProcedure

Procedure S112 ()

	result = get ( "D112" ) + get ( "E112" ) + get ( "F112" ) + get ( "G112" ) + get ( "H112" ) + get ( "I112" ) + get ( "J112" ) + 
	get ( "K112" ) + get ( "L112" ) + get ( "M112" ) + get ( "N112" ) + get ( "O112" ) + get ( "P112" ) + get ( "Q112" ) + get ( "R112" );

EndProcedure

Procedure S113 ()

	result = get ( "D113" ) + get ( "E113" ) + get ( "F113" ) + get ( "G113" ) + get ( "H113" ) + get ( "I113" ) + get ( "J113" ) + 
	get ( "K113" ) + get ( "L113" ) + get ( "M113" ) + get ( "N113" ) + get ( "O113" ) + get ( "P113" ) + get ( "Q113" ) + get ( "R113" );

EndProcedure

Procedure S114 ()

	result = get ( "D114" ) + get ( "E114" ) + get ( "F114" ) + get ( "G114" ) + get ( "H114" ) + get ( "I114" ) + get ( "J114" ) + 
	get ( "K114" ) + get ( "L114" ) + get ( "M114" ) + get ( "N114" ) + get ( "O114" ) + get ( "P114" ) + get ( "Q114" ) + get ( "R114" );

EndProcedure

Procedure S115 ()

	result = get ( "D115" ) + get ( "E115" ) + get ( "F115" ) + get ( "G115" ) + get ( "H115" ) + get ( "I115" ) + get ( "J115" ) + 
	get ( "K115" ) + get ( "L115" ) + get ( "M115" ) + get ( "N115" ) + get ( "O115" ) + get ( "P115" ) + get ( "Q115" ) + get ( "R115" );

EndProcedure

Procedure S116 ()

	result = get ( "D116" ) + get ( "E116" ) + get ( "F116" ) + get ( "G116" ) + get ( "H116" ) + get ( "I116" ) + get ( "J116" ) + 
	get ( "K116" ) + get ( "L116" ) + get ( "M116" ) + get ( "N116" ) + get ( "O116" ) + get ( "P116" ) + get ( "Q116" ) + get ( "R116" );

EndProcedure

Procedure S117 ()

	result = get ( "D117" ) + get ( "E117" ) + get ( "F117" ) + get ( "G117" ) + get ( "H117" ) + get ( "I117" ) + get ( "J117" ) + 
	get ( "K117" ) + get ( "L117" ) + get ( "M117" ) + get ( "N117" ) + get ( "O117" ) + get ( "P117" ) + get ( "Q117" ) + get ( "R117" );

EndProcedure

Procedure S118 ()

	result = get ( "D118" ) + get ( "E118" ) + get ( "F118" ) + get ( "G118" ) + get ( "H118" ) + get ( "I118" ) + get ( "J118" ) + 
	get ( "K118" ) + get ( "L118" ) + get ( "M118" ) + get ( "N118" ) + get ( "O118" ) + get ( "P118" ) + get ( "Q118" ) + get ( "R118" );

EndProcedure

Procedure S119 ()

	result = get ( "D119" ) + get ( "E119" ) + get ( "F119" ) + get ( "G119" ) + get ( "H119" ) + get ( "I119" ) + get ( "J119" ) + 
	get ( "K119" ) + get ( "L119" ) + get ( "M119" ) + get ( "N119" ) + get ( "O119" ) + get ( "P119" ) + get ( "Q119" ) + get ( "R119" );

EndProcedure

Procedure S120 ()

	result = get ( "D120" ) + get ( "E120" ) + get ( "F120" ) + get ( "G120" ) + get ( "H120" ) + get ( "I120" ) + get ( "J120" ) + 
	get ( "K120" ) + get ( "L120" ) + get ( "M120" ) + get ( "N120" ) + get ( "O120" ) + get ( "P120" ) + get ( "Q120" ) + get ( "R120" );

EndProcedure

Procedure S121 ()

	result = get ( "D121" ) + get ( "E121" ) + get ( "F121" ) + get ( "G121" ) + get ( "H121" ) + get ( "I121" ) + get ( "J121" ) + 
	get ( "K121" ) + get ( "L121" ) + get ( "M121" ) + get ( "N121" ) + get ( "O121" ) + get ( "P121" ) + get ( "Q121" ) + get ( "R121" );

EndProcedure

Procedure S122 ()

	result = get ( "D122" ) + get ( "E122" ) + get ( "F122" ) + get ( "G122" ) + get ( "H122" ) + get ( "I122" ) + get ( "J122" ) + 
	get ( "K122" ) + get ( "L122" ) + get ( "M122" ) + get ( "N122" ) + get ( "O122" ) + get ( "P122" ) + get ( "Q122" ) + get ( "R122" );

EndProcedure

Procedure S123 ()

	result = get ( "D123" ) + get ( "E123" ) + get ( "F123" ) + get ( "G123" ) + get ( "H123" ) + get ( "I123" ) + get ( "J123" ) + 
	get ( "K123" ) + get ( "L123" ) + get ( "M123" ) + get ( "N123" ) + get ( "O123" ) + get ( "P123" ) + get ( "Q123" ) + get ( "R123" );

EndProcedure

Procedure S124 ()

	result = get ( "D124" ) + get ( "E124" ) + get ( "F124" ) + get ( "G124" ) + get ( "H124" ) + get ( "I124" ) + get ( "J124" ) + 
	get ( "K124" ) + get ( "L124" ) + get ( "M124" ) + get ( "N124" ) + get ( "O124" ) + get ( "P124" ) + get ( "Q124" ) + get ( "R124" );

EndProcedure

Procedure S125 ()

	result = get ( "D125" ) + get ( "E125" ) + get ( "F125" ) + get ( "G125" ) + get ( "H125" ) + get ( "I125" ) + get ( "J125" ) + 
	get ( "K125" ) + get ( "L125" ) + get ( "M125" ) + get ( "N125" ) + get ( "O125" ) + get ( "P125" ) + get ( "Q125" ) + get ( "R125" );

EndProcedure

Procedure S126 ()

	result = get ( "D126" ) + get ( "E126" ) + get ( "F126" ) + get ( "G126" ) + get ( "H126" ) + get ( "I126" ) + get ( "J126" ) + 
	get ( "K126" ) + get ( "L126" ) + get ( "M126" ) + get ( "N126" ) + get ( "O126" ) + get ( "P126" ) + get ( "Q126" ) + get ( "R126" );

EndProcedure

Procedure S127 ()

	result = get ( "D127" ) + get ( "E127" ) + get ( "F127" ) + get ( "G127" ) + get ( "H127" ) + get ( "I127" ) + get ( "J127" ) + 
	get ( "K127" ) + get ( "L127" ) + get ( "M127" ) + get ( "N127" ) + get ( "O127" ) + get ( "P127" ) + get ( "Q127" ) + get ( "R127" );

EndProcedure

Procedure S128 ()

	result = get ( "D128" ) + get ( "E128" ) + get ( "F128" ) + get ( "G128" ) + get ( "H128" ) + get ( "I128" ) + get ( "J128" ) + 
	get ( "K128" ) + get ( "L128" ) + get ( "M128" ) + get ( "N128" ) + get ( "O128" ) + get ( "P128" ) + get ( "Q128" ) + get ( "R128" );

EndProcedure

Procedure D129 ()

	result = sum ( "D99:D128" );

EndProcedure

Procedure E129 ()

	result = sum ( "E99:E128" );

EndProcedure

Procedure F129 ()

	result = sum ( "F99:F128" );

EndProcedure

Procedure G129 ()

	result = sum ( "G99:G128" );

EndProcedure

Procedure H129 ()

	result = sum ( "H99:H128" );

EndProcedure

Procedure I129 ()

	result = sum ( "I99:I128" );

EndProcedure

Procedure J129 ()

	result = sum ( "J99:J128" );

EndProcedure

Procedure K129 ()

	result = sum ( "K99:K128" );

EndProcedure

Procedure L129 ()

	result = sum ( "L99:L128" );

EndProcedure

Procedure M129 ()

	result = sum ( "M99:M128" );

EndProcedure

Procedure N129 ()

	result = sum ( "N99:N128" );

EndProcedure

Procedure O129 ()

	result = sum ( "O99:O128" );

EndProcedure

Procedure P129 ()

	result = sum ( "P99:P128" );

EndProcedure

Procedure Q129 ()

	result = sum ( "Q99:Q128" );

EndProcedure

Procedure R129 ()

	result = sum ( "R99:R128" );

EndProcedure

Procedure S129 ()

	result = sum ( "S99:S128" );

EndProcedure

Procedure Amount ()

	result = get ( "B51" ) - sum ( "B40:B46" );

EndProcedure

Procedure A51 ()

	result = sum ( "A36:A50" );

EndProcedure

Procedure B51 ()

	result = sum ( "B36:B50" );

EndProcedure