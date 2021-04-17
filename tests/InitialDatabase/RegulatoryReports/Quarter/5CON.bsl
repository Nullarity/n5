Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.HomePhone as HomePhone,
	|	Director.Name as Director, Accountant.Email as Email
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.HomePhone as HomePhone,
	|			Roles.User.Employee.Email as Email
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|		) as Accountant
	|	on true
	|	//
	|	// Director
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.GeneralManager )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|			) as Director
	|	on true
	|where Companies.Ref = &Company
	|;
	|// #TurnoversYear
	|select sum ( Turnovers.AmountTurnoverCr - Turnovers.AmountTurnoverDr ) as Value, substring ( Turnovers.Account.Code, 1, 4 ) as Key
	|from AccountingRegister.General.Turnovers ( beginofperiod ( &DateStart, year ), &DateEnd, , substring ( Account.Code, 1, 4 ) in ( &Accounts ), , Company = &Company, ) as Turnovers
	|group by substring ( Turnovers.Account.Code, 1, 4 )
	|;
	|// #TurnoversQuarter
	|select sum ( Turnovers.AmountTurnoverCr - Turnovers.AmountTurnoverDr ) as Value, substring ( Turnovers.Account.Code, 1, 4 ) as Key
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 4 ) in ( &Accounts ), , Company = &Company, ) as Turnovers
	|group by substring ( Turnovers.Account.Code, 1, 4 )
	|;
	|// Details
	|select Details.Expense as Expense, Details.Row as Row
	|into Details
	|from InformationRegister.ReportDetails as Details
	|where Details.Report.Name = ""5CON""
	|;
	|// #ExpensesYear
	|select sum ( Turnovers.AmountTurnoverDr ) as Value, Details.Row as Key
	|from AccountingRegister.General.Turnovers ( beginofperiod ( &DateStart, year ), &DateEnd, , substring ( Account.Code, 1, 1 ) in ( ""7"", ""8"" ) , , Company = &Company, ) as Turnovers
	|	//
	|	//	ReportDetails
	|	//
	|	join Details as Details
	|	on Details.Expense = Turnovers.ExtDimension1
	|where Details.Row in ( &Rows )
	|group by Details.Row
	|;
	|// #ExpensesQuarter
	|select sum ( Turnovers.AmountTurnoverDr ) as Value, Details.Row as Key
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 1 ) in ( ""7"", ""8"" ) , , Company = &Company, ) as Turnovers
	|	//
	|	//	ReportDetails
	|	//
	|	join Details as Details
	|	on Details.Expense = Turnovers.ExtDimension1
	|where Details.Row in ( &Rows )
	|group by Details.Row
	|";
	Env.Selection.Add ( str );	
	
 	mapField ( "A63", "6111", "Accounts", "TurnoversYear" );
 	mapField ( "B63", "6111", "Accounts", "TurnoversQuarter" );
 	mapField ( "A64", "6112", "Accounts", "TurnoversYear" );
 	mapField ( "B64", "6112", "Accounts", "TurnoversQuarter" );
 	mapField ( "A65", "6113", "Accounts", "TurnoversYear" );
 	mapField ( "B65", "6113", "Accounts", "TurnoversQuarter" );
 	mapField ( "A66", "6115, 6122", "Accounts", "TurnoversYear" );
 	mapField ( "B66", "6115, 6122", "Accounts", "TurnoversQuarter" );
 	mapField ( "A67", "6121, 6123, 6124, 6125, 6126, 6160, 6180", "Accounts", "TurnoversYear" );
 	mapField ( "B67", "6121, 6123, 6124, 6125, 6126, 6160, 6180", "Accounts", "TurnoversQuarter" );
 	
 	// Expenses
 	map = new Map ();
 	map.Insert ( "031", "70" );
 	map.Insert ( "032", "71" );
 	map.Insert ( "033", "72" );
 	map.Insert ( "034", "73" );
 	map.Insert ( "036", "75" );
 	map.Insert ( "038", "77" );
 	map.Insert ( "039", "78" );
 	map.Insert ( "040", "79" );
 	map.Insert ( "041", "80" );
 	map.Insert ( "042", "81" );
 	map.Insert ( "043", "82" );
 	map.Insert ( "049", "83" );
 	map.Insert ( "051", "85" );
 	map.Insert ( "052", "86" );
 	map.Insert ( "053", "87" );
 	map.Insert ( "054", "88" );
 	map.Insert ( "055", "89" );
 	map.Insert ( "056", "90" );
 	map.Insert ( "057", "91" );
 	map.Insert ( "058", "92" );
 	map.Insert ( "059", "93" );
 	map.Insert ( "060", "94" );
 	map.Insert ( "061", "95" );
 	map.Insert ( "062", "96" );
 	map.Insert ( "069", "97" );
 	map.Insert ( "070", "98" );
 	map.Insert ( "071", "99" );
 	map.Insert ( "072", "100" );
 	map.Insert ( "080", "101" );
 	map.Insert ( "091", "103" );
 	map.Insert ( "092", "104" );
 	map.Insert ( "101", "106" );
 	map.Insert ( "102", "107" );
 	map.Insert ( "103", "108" );
 	map.Insert ( "104", "109" );
 	map.Insert ( "105", "110" );
 	map.Insert ( "106", "111" );
 	map.Insert ( "107", "112" );
 	map.Insert ( "108", "113" );
 	map.Insert ( "109", "114" );
 	map.Insert ( "110", "115" );
 	map.Insert ( "111", "116" );
 	map.Insert ( "112", "117" );
 	map.Insert ( "113", "118" );
 	map.Insert ( "114", "119" );
 	map.Insert ( "115", "120" );
 	map.Insert ( "116", "121" );
 	map.Insert ( "117", "122" );
	map.Insert ( "118", "123" );
 	
 	for each item in map do
 		itemKey = item.Key;
 		itemValue = item.Value;
 		mapField ( "A" + itemValue, itemKey, "Rows", "ExpensesYear" );
 		mapField ( "B" + itemValue, itemKey, "Rows", "ExpensesQuarter" );
 	enddo;
 	 	
	getData ();
	
	envFields = Env.Fields;
	// Fields
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	FieldsValues [ "Accountant" ] = envFields.Accountant;
	FieldsValues [ "Director" ] = envFields.Director;
	FieldsValues [ "HomePhone" ] = envFields.HomePhone;
	FieldsValues [ "Email" ] = envFields.Email;
	// Default values
	FieldsValues [ "KindOfActivity" ] = get ( "KindOfActivity", "DefaultValues" );
	FieldsValues [ "CAEM" ] = get ( "CAEM", "DefaultValues" );
	FieldsValues [ "CFP" ] = get ( "CFP", "DefaultValues" );
	FieldsValues [ "CUIO" ] = get ( "CUIO", "DefaultValues" );
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	
	FieldsValues [ "Period" ] = Format ( DateEnd, "L = 'ro_RO';DF='MMMM yyyy'" );
	
	//Last
	FieldsValues [ "Province" ] = getLast ( "Province" );
	FieldsValues [ "Street" ] = getLast ( "Street" );
	FieldsValues [ "Apartment" ] = getLast ( "Apartment" );
	FieldsValues [ "OwnerType" ] = getLast ( "OwnerType" );
	
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A58 ()

	Result = sum ( "A59:A60" ) + get ( "A62" );

EndProcedure

Procedure B58 ()

	Result = sum ( "B59:B60" ) + get ( "B62" );

EndProcedure

Procedure A62 ()

	Result = sum ( "A63:A67" );

EndProcedure

Procedure B62 ()

	Result = sum ( "B63:B67" );

EndProcedure

Procedure A68 ()

	Result = get ( "A69" ) + get ( "A84" ) + get ( "A98" ) + sum ( "A101:A102" ) + get ( "A105" );

EndProcedure

Procedure B68 ()

	Result = get ( "B69" ) + get ( "B84" ) + get ( "B98" ) + sum ( "B101:B102" ) + get ( "B105" );

EndProcedure

Procedure A69 ()

	Result = sum ( "A70:A74" ) + get ( "A105" ) + sum ( "A79:A83" );

EndProcedure

Procedure B69 ()

	Result = sum ( "B70:B74" ) + get ( "B105" ) + sum ( "B79:B83" );

EndProcedure

Procedure A74 ()

	Result = sum ( "A75:A78" );

EndProcedure

Procedure B74 ()

	Result = sum ( "B75:B78" );

EndProcedure

Procedure A84 ()

	Result = sum ( "A85:A87" ) + sum ( "A89:A97" );

EndProcedure

Procedure B84 ()

	Result = sum ( "B85:B87" ) + sum ( "B89:B97" );

EndProcedure

Procedure A102 ()

	Result = sum ( "A103:A104" );

EndProcedure

Procedure B102 ()

	Result = sum ( "B103:B104" );

EndProcedure

Procedure A105 ()

	Result = get ( "A106" ) + sum ( "A108:A111" ) + sum ( "A113:A117" ) + get ( "A123" );

EndProcedure

Procedure B105 ()

	Result = get ( "B106" ) + sum ( "B108:B111" ) + sum ( "B113:B117" ) + get ( "B123" );

EndProcedure
