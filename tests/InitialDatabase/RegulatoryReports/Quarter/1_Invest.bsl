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
	|// #BegBalancesCr
	|select sum ( Balances.AmountBalanceCr ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateStart, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #EndBalancesCr
	|select sum ( Balances.AmountBalanceCr ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateEndBound, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #BegBalancesDr
	|select sum ( Balances.AmountBalanceDr ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateStart, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #EndBalancesDr
	|select sum ( Balances.AmountBalanceDr ) as Value, substring ( Balances.Account.Code, 1, 3 ) as Key
	|from AccountingRegister.General.Balance ( &DateEndBound, substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|group by substring ( Balances.Account.Code, 1, 3 )
	|;
	|// #Turnovers
	|select Turnovers.AmountTurnoverCr as TurnoverCr, Turnovers.AmountTurnoverDr as TurnoverDr,
	|	substring ( Turnovers.Account.Code, 1, 3 ) as Parent, substring ( Account.Code, 1, 2 ) as Class
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 1 ) in ( &Class6_7 ), , Company = &Company, ) as Turnovers
	|";
	
	mapField ( "C125", "311", "Accounts", "BegBalancesCr" );
	mapField ( "D125", "311", "Accounts", "EndBalancesCr" );
	mapField ( "C126", "312", "Accounts", "BegBalancesCr" );
	mapField ( "D126", "312", "Accounts", "EndBalancesCr" );
	mapField ( "C127", "313", "Accounts", "BegBalancesDr" );
	mapField ( "D127", "313", "Accounts", "EndBalancesDr" );
	mapField ( "C129", "315", "Accounts", "BegBalancesDr" );
	mapField ( "D129", "315", "Accounts", "EndBalancesDr" );
	mapField ( "C130", "314", "Accounts", "BegBalancesCr" );
	mapField ( "D130", "314", "Accounts", "EndBalancesCr" );
	mapField ( "C131", "321, 322, 323", "Accounts", "BegBalancesCr" );
	mapField ( "D131", "321, 322, 323", "Accounts", "EndBalancesCr" );
	mapField ( "C133", "341, 342, 343", "Accounts", "BegBalancesCr" );
	mapField ( "D133", "341, 342, 343", "Accounts", "EndBalancesCr" );
	mapField ( "C135", "426, 538", "Accounts", "BegBalancesCr" );
	mapField ( "D135", "426, 538", "Accounts", "EndBalancesCr" );
	mapField ( "C136", "222", "Accounts", "BegBalancesCr" );
	mapField ( "D136", "222", "Accounts", "EndBalancesCr" );
	mapField ( "D138", "334", "Accounts", "EndBalancesDr" );
	mapField ( "D139", "331", "Accounts", "EndBalancesCr" );
	mapField ( "C135", "335", "Accounts", "BegBalancesCr" );
	mapField ( "D135", "335", "Accounts", "EndBalancesCr" );
	
	class6_7 = new Array ();
	class6_7.Add ( "6" );
	class6_7.Add ( "7" );
	
	Env.Selection.Add ( str );	
	q = Env.Q;
 	q.SetParameter ( "Company", Company );
 	q.SetParameter ( "Class6_7", class6_7 );
 	q.SetParameter ( "DateEndBound", new Boundary ( DateEnd, BoundaryType.Including ) );
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
	
	for i = 151 to 156 do
 		FieldsValues [ "D" + i ] = 0;
 	enddo; 
 	
 	for each row in Env.Turnovers do
 	
 		if ( row.Class = "61" ) then
 			FieldsValues [ "D151" ] = FieldsValues [ "D151" ] + row.TurnoverCr;
 		endif;
 		if ( row.Class = "71" ) then
 			FieldsValues [ "D151" ] = FieldsValues [ "D151" ] - row.TurnoverDr;
 		endif;
 		if ( row.Parent = "621" ) then
 			FieldsValues [ "D152" ] = FieldsValues [ "D152" ] + row.TurnoverCr;
 		endif;
 		if ( row.Parent = "721" ) then
 			FieldsValues [ "D152" ] = FieldsValues [ "D152" ] - row.TurnoverDr;
 		endif;
 		if ( row.Parent = "622" ) then
 			FieldsValues [ "D153" ] = FieldsValues [ "D153" ] + row.TurnoverCr;
 		endif;
 		if ( row.Parent = "722" ) then
 			FieldsValues [ "D153" ] = FieldsValues [ "D153" ] - row.TurnoverDr;
 		endif;
 		if ( row.Parent = "623" ) then
 			FieldsValues [ "D154" ] = FieldsValues [ "D154" ] + row.TurnoverCr;
 		endif;
 		if ( row.Parent = "723" ) then
 			FieldsValues [ "D154" ] = FieldsValues [ "D154" ] - row.TurnoverDr;
 		endif;
 		if ( row.Parent = "731" ) then
 			FieldsValues [ "D156" ] = FieldsValues [ "D156" ] + row.TurnoverDr;
 		endif;
 		
 	enddo;	
	
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

Procedure C134 ()

	Result = sum ( "C125:C126" ) - get ( "C127" ) - get ( "C129" ) + sum ( "C130:C133" );

EndProcedure

Procedure D134 ()

	Result = sum ( "D125:D126" ) - get ( "D127" ) - get ( "D129" ) + sum ( "D130:D133" );

EndProcedure

Procedure D155 ()

	Result = sum ( "D151:D154" );

EndProcedure

