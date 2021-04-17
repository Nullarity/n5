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
	|// @Salary
	|select sum ( Documents.Amount ) as Amount
	|from Document.PayEmployees.Compensations as Documents
	|where Documents.Ref.Posted
	|and Documents.Ref.Date between &DateStart and &DateEnd
	|and Documents.Ref.Company = &Company
	|;
	|// @Taxes
	|select sum ( case when Taxes.Method in ( value ( Enum.Calculations.IncomeTax ), value ( Enum.Calculations.FixedIncomeTax ) ) then Taxes.Result else 0 end ) as Income,
	|	sum ( case when Taxes.Method in ( value ( Enum.Calculations.MedicalInsurance ), value ( Enum.Calculations.MedicalInsuranceEmployee ) ) then Taxes.Result else 0 end ) as Medical
	|from Document.PayEmployees.Taxes as Taxes
	|where Taxes.Ref.Posted
	|and Taxes.Ref.Date between &DateStart and &DateEnd
	|and Taxes.Ref.Company = &Company
	|;
	|// Income
	|select Incomes.Recorder as Recorder, Incomes.AccountDr as Account, Incomes.Amount as Amount,
	|	Incomes.ExtDimensionCr1 as Code
	|into Income
	|from AccountingRegister.General.RecordsWithExtDimensions ( &DateStart, &DateEnd, AccountCr.Code = ""5343""
	|and Company = &Company and ExtDimensionCr1 <> value ( Enum.IncomeCodes.EmptyRef ) , , ) as Incomes
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
	|// #Table1
	|select Income.Amount as IncomeAmount, presentation ( Income.Code ) as Code, Base.Amount as BaseAmount,
	|	case when Income.Code = value ( Enum.IncomeCodes.DOB ) then ""34""
	|		when Income.Code = value ( Enum.IncomeCodes.PL ) then ""35""
	|		when Income.Code = value ( Enum.IncomeCodes.PLs ) then ""36""
	|		when Income.Code = value ( Enum.IncomeCodes.FOL ) then ""37""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVA ) then ""38""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSA ) then ""39""
	|		when Income.Code = value ( Enum.IncomeCodes.ROY ) then ""40""
	|		when Income.Code = value ( Enum.IncomeCodes.NOR ) then ""41""
	|		when Income.Code = value ( Enum.IncomeCodes.PUB ) then ""42""
	|		when Income.Code = value ( Enum.IncomeCodes.LIV ) then ""43""
	|		when Income.Code = value ( Enum.IncomeCodes.CSM ) then ""44""
	|		when Income.Code = value ( Enum.IncomeCodes.ROYb ) then ""45""
	|		when Income.Code = value ( Enum.IncomeCodes.DOBb ) then ""46""
	|		when Income.Code = value ( Enum.IncomeCodes.CC ) then ""47""
	|		when Income.Code = value ( Enum.IncomeCodes.DIVB ) then ""48""
	|		when Income.Code = value ( Enum.IncomeCodes.RCSB ) then ""49""
	|		when Income.Code = value ( Enum.IncomeCodes.PLT ) then ""50""
	|		else ""Continue""
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
	|// #Divisions
	|select Divisions.Code as Code, Divisions.Cutam as Cutam
	|from Catalog.Divisions as Divisions
	|where not Divisions.DeletionMark
	|and Divisions.Owner = &Company
	|order by Divisions.Code
	|;
	|// Employees
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName as Name, Employees.Individual.PIN as PIN, ""01"" as Status,
	|	Employees.Individual.SIN as SIN, Employees.DateStart as Date, Employees.Individual as Individual, 
	|	Employees.Individual.Birthday as Birthday
	|into Employees	
	|from Document.Hiring.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.Ref.Date between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|union
	|select Employees.Individual.LastName + "" "" + Employees.Individual.FirstName, Employees.Individual.PIN, ""02"" as Status,
	|	Employees.Individual.SIN, Employees.Date, Employees.Individual,	Employees.Individual.Birthday
	|from Document.Termination.Employees as Employees
	|where Employees.Ref.Posted
	|and Employees.Ref.Date between &DateStart and &DateEnd
	|and Employees.Ref.Company = &Company
	|;
	|// #Hiring
	|select Employees.Name as Name, Employees.PIN as PIN, Employees.Status as Status, Employees.SIN as SIN, Employees.Date as Date,
	|	Employees.Individual as Individual, Employees.Birthday as Birthday
	|from Employees as Employees
	|group by Employees.Name, Employees.PIN, Employees.Status, Employees.SIN, Employees.Date,
	|	Employees.Individual, Employees.Birthday
	|order by Employees.Name, Employees.Status
	|;
	|// #IndividualsHiring
	|select distinct Employees.Individual as Individual, Employees.Name as Name
	|from Employees as Employees
	|order by Employees.Name
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
	
	// Default values
	FieldsValues [ "CUATM" ] = get ( "CUATM", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "TaxAdministration" ] = get ( "TaxAdministration", "DefaultValues" );
	FieldsValues [ "CNAS" ] = get ( "CNAS", "DefaultValues" );
	
	// Period
	FieldsValues [ "Period" ] = DateStart;
	
	// *********
	// Table1
	// *********
	
	salaryAmount = Env.Salary.Amount;
	FieldsValues [ "A32" ] = ? ( salaryAmount = null, 0 , salaryAmount );
	taxes = Env.Taxes;
	medical = taxes.Medical;
	income = taxes.Income;
	FieldsValues [ "B32" ] = ? ( medical = null, 0 , medical );
	FieldsValues [ "C32" ] = ? ( income = null, 0 , income );
	
	for each row in Env.Table1 do
	    if ( row.Row = "Continue" ) then
	    	continue;
	    endif;
		FieldsValues [ "A" + row.Row ] = row.BaseAmount;
		FieldsValues [ "B" + row.Row ] = row.IncomeAmount;
	enddo;
	
	// *********
	// Table1 annex
	// *********
	
	line = 1;
	rowNumber = 87;
	for each row in Env.Divisions do
		FieldsValues [ "A" + rowNumber ] = line;
		FieldsValues [ "B" + rowNumber ] = row.Code;
		FieldsValues [ "C" + rowNumber ] = row.Cutam;
		rowNumber = rowNumber + 1;
		line = line + 1;
	enddo;
	
	// *********
	// Table2
	// *********
	
	line = 1;
	rowNumber = 137;
	hiring = Env.Hiring;
	filter = new Structure ( "Individual" );
	for each row in Env.IndividualsHiring do
		filter.Individual = row.Individual;
		for each rowHiring in hiring.FindRows ( filter ) do
			FieldsValues [ "A" + rowNumber ] = line;
			FieldsValues [ "B" + rowNumber ] = rowHiring.Name;
			FieldsValues [ "C" + rowNumber ] = rowHiring.PIN;
			FieldsValues [ "D" + rowNumber ] = rowHiring.SIN;
			FieldsValues [ "F" + rowNumber ] = rowHiring.Birthday;
			FieldsValues [ "G" + rowNumber ] = rowHiring.Status;
			FieldsValues [ "H" + rowNumber ] = rowHiring.Date;
			rowNumber = rowNumber + 1;
		enddo;
		line = line + 1;
	enddo;
	
	~draw:
	
	area = getArea ();
	
	TabDoc.PageOrientation = PageOrientation.Landscape;	
	draw ();

EndProcedure

//****************
// Table 1
//****************

Procedure A51 ()

	result = sum ( "A32:A50" );

EndProcedure

Procedure B51 ()

	result = sum ( "B32:B35" ) + sum ( "B37:B50" );

EndProcedure

Procedure C51 ()

	result = sum ( "C32:C33" );

EndProcedure

//****************
// Table 1 annex
//****************

Procedure D125 ()

	result = sum ( "D87:D124" );

EndProcedure

Procedure E125 ()

	result = sum ( "E87:E124" );

EndProcedure

Procedure F125 ()

	result = sum ( "F87:F124" );

EndProcedure

Procedure D87 ()

	result = sum ( "E87:F87" );

EndProcedure

Procedure D88 ()

	result = sum ( "E88:F88" );

EndProcedure


Procedure D89 ()

	result = sum ( "E89:F89" );

EndProcedure

Procedure D90 ()

	result = sum ( "E90:F90" );

EndProcedure

Procedure D91 ()

	result = sum ( "E91:F91" );

EndProcedure

Procedure D92 ()

	result = sum ( "E92:F92" );

EndProcedure

Procedure D93 ()

	result = sum ( "E93:F93" );

EndProcedure

Procedure D94 ()

	result = sum ( "E94:F94" );

EndProcedure

Procedure D95 ()

	result = sum ( "E95:F95" );

EndProcedure

Procedure D96 ()

	result = sum ( "E96:F96" );

EndProcedure

Procedure D97 ()

	result = sum ( "E97:F97" );

EndProcedure

Procedure D98 ()

	result = sum ( "E98:F98" );

EndProcedure

Procedure D99 ()

	result = sum ( "E99:F99" );

EndProcedure

Procedure D100 ()

	result = sum ( "E100:F100" );

EndProcedure

Procedure D101 ()

	result = sum ( "E101:F101" );

EndProcedure

Procedure D102 ()

	result = sum ( "E102:F102" );

EndProcedure

Procedure D103 ()

	result = sum ( "E103:F103" );

EndProcedure

Procedure D104 ()

	result = sum ( "E104:F104" );

EndProcedure

Procedure D105 ()

	result = sum ( "E105:F105" );

EndProcedure

Procedure D106 ()

	result = sum ( "E106:F106" );

EndProcedure

Procedure D107 ()

	result = sum ( "E107:F107" );

EndProcedure

Procedure D108 ()

	result = sum ( "E108:F108" );

EndProcedure

Procedure D109 ()

	result = sum ( "E109:F109" );

EndProcedure

Procedure D110 ()

	result = sum ( "E110:F110" );

EndProcedure

Procedure D111 ()

	result = sum ( "E111:F111" );

EndProcedure

Procedure D112 ()

	result = sum ( "E112:F112" );

EndProcedure

Procedure D113 ()

	result = sum ( "E113:F113" );

EndProcedure

Procedure D114 ()

	result = sum ( "E114:F114" );

EndProcedure

Procedure D115 ()

	result = sum ( "E115:F115" );

EndProcedure

Procedure D116 ()

	result = sum ( "E116:F116" );

EndProcedure

Procedure D117 ()

	result = sum ( "E117:F117" );

EndProcedure

Procedure D118 ()

	result = sum ( "E118:F118" );

EndProcedure

Procedure D119 ()

	result = sum ( "E119:F119" );

EndProcedure

Procedure D120 ()

	result = sum ( "E120:F120" );

EndProcedure

Procedure D121 ()

	result = sum ( "E121:F121" );

EndProcedure

Procedure D122 ()

	result = sum ( "E122:F122" );

EndProcedure

Procedure D123 ()

	result = sum ( "E123:F123" );

EndProcedure

Procedure D124 ()

	result = sum ( "E124:F124" );

EndProcedure


//****************
// Table 3
//****************

Procedure I339 ()

	result = sum ( "I191:I338" );

EndProcedure

Procedure J339 ()

	result = sum ( "J191:J338" );

EndProcedure

Procedure K339 ()

	result = sum ( "K191:K338" );

EndProcedure

Procedure L339 ()

	result = sum ( "L191:L338" );

EndProcedure
