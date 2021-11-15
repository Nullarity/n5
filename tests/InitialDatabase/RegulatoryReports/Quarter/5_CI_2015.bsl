Procedure Make ()

	if ( Calculated ) then
		goto ~draw;
	endif;
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.HomePhone as HomePhone,
	|	Director.Name as Director
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.HomePhone as HomePhone
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
	|// #BalancesBegin
	|select sum ( case when substring ( Balances.Account.Code, 1, 3 ) = ""214"" then -Balances.AmountBalanceCr else Balances.AmountBalanceDr end ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateStart, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #BalancesEnd
	|select sum ( case when substring ( Balances.Account.Code, 1, 3 ) = ""214"" then -Balances.AmountBalanceCr else Balances.AmountBalanceDr end ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateEndBound, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #Turnovers
	|select sum ( case when substring ( Turnovers.Account.Code, 1, 1 ) = ""6"" then Turnovers.AmountTurnoverCr else Turnovers.AmountTurnoverDr end ) as Value, 
	|	substring ( Turnovers.Account.Code, 1, 4 ) as Key
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 4 ) in ( &Accounts ), , Company = &Company, ) as Turnovers
	|group by substring ( Turnovers.Account.Code, 1, 4 )
	|;
	|// #IncomesTotals
	|select sum ( Turnovers.AmountTurnoverCr ) as Value, substring ( Turnovers.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 3 ) in ( &AccountsTotals ), , Company = &Company, ) as Turnovers
	|group by substring ( Turnovers.Account.Code, 1, 3 )
	|;
	|// Details
	|select Details.Expense as Expense, Details.Row as Row
	|into Details
	|from InformationRegister.ReportDetails as Details
	|where Details.Report.Name = ""5_CI_2015""
	|;
	|// #Expenses
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
	q = Env.Q;
 	q.SetParameter ( "Company", Company );
 	
 	month = Month ( DateStart );
 	if ( month = 1 ) then
 		quarter = "I";
 	elsif ( month = 4 ) then
 		quarter = "II";
 	elsif ( month = 7 ) then
 		quarter = "III";
 	else
 		quarter = "IV";
 	endif;	
 	
 	q.SetParameter ( "DateEndBound", new Boundary ( DateEnd, BoundaryType.Including ) );
 	
 	// Balances
 	
 	map = new Map ();
 	map.Insert ( "39", "211" );
 	map.Insert ( "40", "212" );
 	map.Insert ( "41", "213, 214" );
 	map.Insert ( "42", "215" );
 	map.Insert ( "43", "216" );
 	map.Insert ( "44", "217" );
 	
 	for each item in map do
 		itemKey = item.Key;
 		itemValue = item.Value;
 		mapField ( "A" + itemKey, itemValue, "Accounts", "BalancesBegin" );
 		mapField ( "B" + itemKey, itemValue, "Accounts", "BalancesEnd" );
 	enddo;
 	
 	// Incomes
 	mapField ( "A68", "612", "AccountsTotals", "IncomesTotals" );
 	mapField ( "A53", "6111", "Accounts", "Turnovers" );
 	mapField ( "A55", "6112", "Accounts", "Turnovers" );
 	mapField ( "A58", "6113, 6114, 6117, 6118", "Accounts", "Turnovers" );
 	mapField ( "A64", "6115", "Accounts", "Turnovers" );
 	mapField ( "A66", "6116", "Accounts", "Turnovers" );
 	mapField ( "A69", "7112", "Accounts", "Turnovers" );
 	
 	// Expenses
 	mapField ( "A71", "0300", "Rows", "Expenses" );
 	mapField ( "A72", "0310", "Rows", "Expenses" );
 	mapField ( "A73", "0320", "Rows", "Expenses" );
 	mapField ( "A74", "0500", "Rows", "Expenses" );
 	mapField ( "A75", "0510", "Rows", "Expenses" );
 	mapField ( "A76", "0520", "Rows", "Expenses" );
 	mapField ( "A77", "0540", "Rows", "Expenses" );
 	mapField ( "A78", "0700", "Rows", "Expenses" );
 	mapField ( "A79", "0800", "Rows", "Expenses" );
 	mapField ( "A80", "0900", "Rows", "Expenses" );
 	mapField ( "A81", "1000", "Rows", "Expenses" );
 	mapField ( "A82", "1010", "Rows", "Expenses" );
 	mapField ( "A83", "1050", "Rows", "Expenses" );
 	mapField ( "A84", "1200", "Rows", "Expenses" );
 	mapField ( "A93", "1510", "Rows", "Expenses" );
 	mapField ( "A94", "1520", "Rows", "Expenses" );
 	mapField ( "A95", "1530", "Rows", "Expenses" );
 	
 	getData ();
	
	envFields = Env.Fields;
	// Fields
	FieldsValues [ "Company" ] = envFields.Company;
	FieldsValues [ "CodeFiscal" ] = envFields.CodeFiscal;
	FieldsValues [ "Accountant" ] = envFields.Accountant;
	FieldsValues [ "Director" ] = envFields.Director;
	FieldsValues [ "HomePhone" ] = envFields.HomePhone;
	FieldsValues [ "Quarter" ] = quarter;
	// Default values
	FieldsValues [ "CUIO" ] = get ( "CUIO", "DefaultValues" );
	FieldsValues [ "Region" ] = get ( "Region", "DefaultValues" );
	
	//Last
	FieldsValues [ "Province" ] = getLast ( "Province" );
	FieldsValues [ "Street" ] = getLast ( "Street" );
	FieldsValues [ "Apartment" ] = getLast ( "Apartment" );
	
	~draw:
	
	area = getArea ();
	draw ();
	if ( not InternalProcessing ) then
   		TabDoc.FitToPage = true;
	endif;

EndProcedure

Procedure A45 ()

	Result = sum ( "A39:A44" );

EndProcedure

Procedure B45 ()

	Result = sum ( "B39:B44" );

EndProcedure

Procedure A52 ()

	Result = get ( "A53" ) + get ( "A55" ) + get ( "A58" ) + get ( "A64" ) + get ( "A66" );

EndProcedure

Procedure A70 ()

	Result = get ( "A71" ) + get ( "A74" ) + sum ( "A78:A81" );

EndProcedure

Procedure A92 ()

	Result = sum ( "A93:A95" );

EndProcedure
