Procedure Make ()
	
	str = "
	|// @Fields
	|select Companies.FullDescription as Company, Companies.CodeFiscal as CodeFiscal, Accountant.Name as Accountant, Accountant.MobilePhone as MobilePhone
	|from Catalog.Companies as Companies
	|	//
	|	// Accountant
	|	//
	|	left join (
	|		select top 1 Roles.User.Employee.Individual.Description as Name, Roles.User.Employee.MobilePhone as MobilePhone
	|		from Document.Roles as Roles
	|		where Roles.Role = value ( Enum.Roles.AccountantChief )
	|		and not Roles.DeletionMark
	|		and Roles.Action = value ( Enum.AssignRoles.Assign )
	|		and Roles.Company = &Company
	|		order by Roles.Date desc
	|		) as Accountant
	|	on true
	|where Companies.Ref = &Company
	|";
	Env.Selection.Add ( str );
	if ( Calculated ) then
		q = Env.Q;
		getData ();
		goto ~draw;
	endif;
	
	str = "
	|// #_050
	|select ""Current"" as Key, sum ( Balances.Value ) as Value
	|from ( 
	|	select -Balances.AmountBalanceDr as Value
	|	from AccountingRegister.General.Balance ( &DateEnd, Account in hierarchy ( value ( ChartOfAccounts.General._215 ),
	|										value ( ChartOfAccounts.General._216 ) ), , Company = &Company ) as Balances
	|	union all
	|	select Balances.AmountBalanceDr
	|	from AccountingRegister.General.Balance ( &DateStart, Account in hierarchy ( value ( ChartOfAccounts.General._215 ),
	|										value ( ChartOfAccounts.General._216 ) ), , Company = &Company ) as Balances
	|	) as Balances
	|union all
	|select ""Last"", sum ( Balances.Value )
	|from ( 
	|	select -Balances.AmountBalanceDr as Value
	|	from AccountingRegister.General.Balance ( &LastYearDateEnd, Account in hierarchy ( value ( ChartOfAccounts.General._215 ),
	|										value ( ChartOfAccounts.General._216 ) ), , Company = &Company ) as Balances
	|	union all
	|	select Balances.AmountBalanceDr
	|	from AccountingRegister.General.Balance ( &LastYearDateStart, Account in hierarchy ( value ( ChartOfAccounts.General._215 ),
	|										value ( ChartOfAccounts.General._216 ) ), , Company = &Company ) as Balances
	|	) as Balances
	|;
	|// Turnovers Current
	|select Turnovers.Account as Account, Turnovers.AmountTurnoverCr as TurnoverCr, substring ( Turnovers.BalancedAccount.Code, 1, 3 ) as BalancedParent, 
	|	Turnovers.AmountTurnoverDr as TurnoverDr, substring ( Turnovers.BalancedAccount.Code, 1, 4 ) as BalancedCode
	|into TurnoversCurrent
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 1 ) in ( &Class6_8 ), , Company = &Company, ) as Turnovers
	|;
	|// Turnovers Last
	|select Turnovers.Account as Account, Turnovers.AmountTurnoverCr as TurnoverCr, substring ( Turnovers.BalancedAccount.Code, 1, 3 ) as BalancedParent, 
	|	Turnovers.AmountTurnoverDr as TurnoverDr, substring ( Turnovers.BalancedAccount.Code, 1, 4 ) as BalancedCode
	|into TurnoversLast
	|from AccountingRegister.General.Turnovers ( &LastYearDateStart, &LastYearDateEnd, , substring ( Account.Code, 1, 1 ) in ( &Class6_8 ), , Company = &Company, ) as Turnovers
	|;
	|// #Turnovers
	|select substring ( General.Code, 1, 3 ) as Parent, substring ( General.Code, 1, 4 ) as Code, isnull ( TurnoversCurrent.BalancedParent, TurnoversLast.BalancedParent ) as BalancedParent,
	|	isnull ( TurnoversCurrent.TurnoverCr, 0 ) as CurrentTurnoverCr, isnull ( TurnoversLast.TurnoverCr, 0 ) as LastTurnoverCr, 
	|	isnull ( TurnoversCurrent.TurnoverDr, 0 ) as CurrentTurnoverDr, isnull ( TurnoversLast.TurnoverDr, 0 ) as LastTurnoverDr, 
	|	isnull ( TurnoversCurrent.BalancedCode, TurnoversLast.BalancedCode ) as BalancedCode 
	|from ChartOfAccounts.General as General
	|	//
	|	//	Turnovers Current
	|	//
	|	left join TurnoversCurrent as TurnoversCurrent
	|	on TurnoversCurrent.Account = General.Ref
	|	//
	|	//	Turnovers Last
	|	//
	|	left join TurnoversLast as TurnoversLast
	|	on TurnoversLast.Account = General.Ref
	|where not TurnoversCurrent.TurnoverCr is null 
	|	or not TurnoversCurrent.TurnoverDr is null 
	|	or not TurnoversLast.TurnoverDr is null
	|	or not TurnoversLast.TurnoverCr is null
	|;
	|// #Balances
	|select substring ( Balances.Account.Code, 1, 3 ) as Parent, substring ( Balances.Account.Code, 1, 4 ) as Code, 
	|	Balances.AmountClosingBalanceDr as CurrentBalanceDr, Balances.AmountClosingBalanceCr as CurrentBalanceCr, Balances.AmountTurnoverDr as TurnoverDr,
	|	Balances.AmountOpeningBalanceDr as LastBalanceDr, Balances.AmountOpeningBalanceCr as LastBalanceCr, Balances.AmountTurnoverCr as TurnoverCr
	|from AccountingRegister.General.BalanceAndTurnovers ( &DateStart, &DateEnd, , , , , Company = &Company ) as Balances
	|;
	|// #Debits
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnoverDr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &Debits )
	|;
	|// #DebitsMinusCredits
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnover as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &DebitsMinusCredits )
	|;
	|// #Credits
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &DateStart, &DateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &Credits )
	|;
	|// #DebitsLastYear
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnoverDr as Value
	|from AccountingRegister.General.Turnovers ( &LastYearDateStart, &LastYearDateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &Debits )
	|;
	|// #DebitsMinusCreditsLastYear
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnover as Value
	|from AccountingRegister.General.Turnovers ( &LastYearDateStart, &LastYearDateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &DebitsMinusCredits )
	|;
	|// #CreditsLastYear
	|select cast ( ExtDimension1 as Catalog.CashFlows ).Code as Key, AmountTurnoverCr as Value
	|from AccountingRegister.General.Turnovers ( &LastYearDateStart, &LastYearDateEnd, , substring ( Account.Code, 1, 3 ) in ( &Accounts ), value ( ChartOfCharacteristicTypes.Dimensions.CashFlows ), Company = &Company ) as Turnovers
	|where cast ( Turnovers.ExtDimension1 as Catalog.CashFlows ).Code in ( &Credits )
	|;
	|// #BalancesMoney
	|select Balances.AmountClosingBalanceDr as CurrentBalanceDr, Balances.AmountOpeningBalanceDr as LastBalanceDr
	|from AccountingRegister.General.BalanceAndTurnovers ( &LastYearDateStart, endofperiod ( &LastYearDateEnd, year ), , , substring ( Account.Code, 1, 3 ) in ( &Accounts ), , Company = &Company ) as Balances
	|";
	
	//if ( not Calculated ) then
	
	Env.Selection.Add ( str );
	
	mapField ( "A200", "010", "Debits", "DebitsLastYear" );
	mapField ( "B200", "010", "Debits", "Debits" );
	mapField ( "A201", "020", "Credits", "CreditsLastYear" );
	mapField ( "B201", "020", "Credits", "Credits" );
	mapField ( "A202", "030", "Credits", "CreditsLastYear" );
	mapField ( "B202", "030", "Credits", "Credits" );
	mapField ( "A203", "040", "Credits", "CreditsLastYear" );
	mapField ( "B203", "040", "Credits", "Credits" );
	mapField ( "A204", "050", "Credits", "CreditsLastYear" );
	mapField ( "B204", "050", "Credits", "Credits" );
	mapField ( "A205", "060", "Debits", "DebitsLastYear" );
	mapField ( "B205", "060", "Debits", "Debits" );
	mapField ( "A206", "070", "Credits", "CreditsLastYear" );
	mapField ( "B206", "070", "Credits", "Credits" );
	mapField ( "A208", "090", "Debits", "DebitsLastYear" );
	mapField ( "B208", "090", "Debits", "Debits" );
	mapField ( "A209", "100", "Credits", "CreditsLastYear" );
	mapField ( "B209", "100", "Credits", "Credits" );
	mapField ( "A210", "110", "Debits", "DebitsLastYear" );
	mapField ( "B210", "110", "Debits", "Debits" );
	mapField ( "A211", "120, 121", "Debits", "DebitsLastYear" );
	mapField ( "B211", "120, 121", "Debits", "Debits" );
	mapField ( "A212", "130", "DebitsMinusCredits", "DebitsMinusCreditsLastYear" );
	mapField ( "B212", "130", "DebitsMinusCredits", "DebitsMinusCredits" );
	mapField ( "A214", "150", "Debits", "DebitsLastYear" );
	mapField ( "B214", "150", "Debits", "Debits" );
	mapField ( "A215", "160", "Credits", "CreditsLastYear" );
	mapField ( "B215", "160", "Credits", "Credits" );
	mapField ( "A216", "170, 171", "Credits", "CreditsLastYear" );
	mapField ( "B216", "170, 171", "Credits", "Credits" );
	mapField ( "A217", "180", "Debits", "DebitsLastYear" );
	mapField ( "B217", "180", "Debits", "Debits" );
	mapField ( "A218", "190, 200", "DebitsMinusCredits", "DebitsMinusCreditsLastYear" );
	mapField ( "B218", "190, 200", "DebitsMinusCredits", "DebitsMinusCredits" );
	mapField ( "A221", "250", "DebitsMinusCredits", "DebitsMinusCreditsLastYear" );
	mapField ( "B221", "250", "DebitsMinusCredits", "DebitsMinusCredits" );
	
	accounts = new Array ();
	accounts.Add ( "241" );
	accounts.Add ( "242" );
	accounts.Add ( "243" );
	accounts.Add ( "244" );
	
	class6_8 = new Array ();
	class6_8.Add ( "6" );
	class6_8.Add ( "7" );
	class6_8.Add ( "8" );
	
	q = Env.Q;
	q.SetParameter ( "Accounts", accounts );
	q.SetParameter ( "Class6_8", class6_8 );
	
	getData ();
	
	s = "| ";
	max = 8;
	text = get ( "CUIO", "DefaultValues" );
	for i = 1 to max do
		char = Mid ( text, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = max, " |", " | " );
	enddo;
	FieldsValues [ "CUIO" ] = s;
	
	s = "| ";
	max = 6;
	text = get ( "CAEM", "DefaultValues" );
	for i = 1 to max do
		char = Mid ( text, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = max, " |", " | " );
	enddo;
	FieldsValues [ "CAEM" ] = s;
	
	s = "| ";
	max = 2;
	text = get ( "CFP", "DefaultValues" );
	for i = 1 to max do
		char = Mid ( text, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = max, " |", " | " );
	enddo;
	FieldsValues [ "CFP" ] = s;
	
	s = "| ";
	max = 3;
	text = get ( "CFOJ", "DefaultValues" );
	for i = 1 to max do
		char = Mid ( text, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = max, " |", " | " );
	enddo;
	FieldsValues [ "CFOJ" ] = s;
	
	s = "| ";
	max = 4;
	text = get ( "CUATM", "DefaultValues" );
	for i = 1 to max do
		char = Mid ( text, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = max, " |", " | " );
	enddo;
	FieldsValues [ "CUATM" ] = s;
	FieldsValues [ "KindOfActivity" ] = get ( "KindOfActivity", "DefaultValues" );
	
	for i = 43 to 58 do
		FieldsValues [ "A" + i ] = 0;
		FieldsValues [ "B" + i ] = 0;
	enddo;
	for i = 200 to 223 do
		FieldsValues [ "A" + i ] = 0;
		FieldsValues [ "B" + i ] = 0;
	enddo;
	for i = 71 to 188 do
		FieldsValues [ "C" + i ] = 0;
		FieldsValues [ "D" + i ] = 0;
	enddo;
	for i = 169 to 188 do
		FieldsValues [ "E" + i ] = 0;
		FieldsValues [ "F" + i ] = 0;
	enddo;
	
	table = Env.BalancesMoney;
	FieldsValues [ "A222" ] = table.Total ( "LastBalanceDr" );
	FieldsValues [ "B222" ] = table.Total ( "CurrentBalanceDr" );
	
	prefixLast = "C";
	prefixCurrent = "D";
	
	for each row in Env.Turnovers do
		
		// *******************
		// Notă informativă privind veniturile şi cheltuielile clasificate după natură
		// *******************
		
		if ( row.Parent = "611" ) then
			FieldsValues [ "A43" ] = FieldsValues [ "A43" ] + row.LastTurnoverCr;
			FieldsValues [ "B43" ] = FieldsValues [ "B43" ] + row.CurrentTurnoverCr;
		endif;	
		if ( row.Parent = "612"
			or row.Parent = "613"	
			or row.Parent = "616"
			or row.Parent = "617"
			or row.Parent = "618" ) then
			FieldsValues [ "A44" ] = FieldsValues [ "A44" ] + row.LastTurnoverCr;
			FieldsValues [ "B44" ] = FieldsValues [ "B44" ] + row.CurrentTurnoverCr;
		endif;	
		if ( row.Parent = "621"
			or row.Parent = "622"	
			or row.Parent = "623" ) then
			FieldsValues [ "A45" ] = FieldsValues [ "A45" ] + row.LastTurnoverCr;
			FieldsValues [ "B45" ] = FieldsValues [ "B45" ] + row.CurrentTurnoverCr;	
		endif;
		if ( row.Code = "7112" ) then
			FieldsValues [ "A48" ] = FieldsValues [ "A48" ] + row.LastTurnoverDr;
			FieldsValues [ "B48" ] = FieldsValues [ "B48" ] + row.CurrentTurnoverDr;	
		endif;	
		if ( row.Parent = "711"
			or row.Parent = "712"	
			or row.Parent = "713"
			or row.Parent = "714"
			or row.Parent = "715"
			or row.Parent = "716"
			or row.Parent = "717"
			or row.Parent = "718"
			or row.Parent = "721"
			or row.Parent = "722"
			or row.Parent = "723"
			or row.Parent = "731" ) then
			if ( row.BalancedParent = "211" 
				or row.BalancedParent = "212"
				or row.BalancedParent = "213"
				or row.BalancedParent = "214" ) then
				FieldsValues [ "A49" ] = FieldsValues [ "A49" ] + row.LastTurnoverDr;
				FieldsValues [ "B49" ] = FieldsValues [ "B49" ] + row.CurrentTurnoverDr;		
			endif;	
			if ( row.BalancedParent = "124" 
				or row.BalancedParent = "129"
				or row.BalancedParent = "113"
				or row.BalancedParent = "126"
				or row.BalancedParent = "133"
				or row.BalancedParent = "127"
				or row.BalancedParent = "128"
				or row.BalancedParent = "152" ) then
				FieldsValues [ "A52" ] = FieldsValues [ "A52" ] + row.LastTurnoverDr;
				FieldsValues [ "B52" ] = FieldsValues [ "B52" ] + row.CurrentTurnoverDr;		
			endif;	
		endif;
		if ( row.Parent = "711"
			or row.Parent = "712"	
			or row.Parent = "713"
			or row.Parent = "714"
			or row.Parent = "715"
			or row.Parent = "716"
			or row.Parent = "717"
			or row.Parent = "718"
			or row.Parent = "721"
			or row.Parent = "722"
			or row.Parent = "723"
			or row.Parent = "731"
			or row.Parent = "811"
			or row.Parent = "812"
			or row.Parent = "813"
			or row.Parent = "822"
			or row.Parent = "823"
			or row.Parent = "824"
			or row.Parent = "833"
			or row.Parent = "834"
			or row.Parent = "835"
			or row.Parent = "836" ) then
			if ( row.BalancedParent = "531" ) then
				FieldsValues [ "A50" ] = FieldsValues [ "A50" ] + row.LastTurnoverDr;
				FieldsValues [ "B50" ] = FieldsValues [ "B50" ] + row.CurrentTurnoverDr;
			endif;
			if ( row.BalancedCode = "5331"
				or row.BalancedParent = "541" ) then
				FieldsValues [ "A51" ] = FieldsValues [ "A51" ] + row.LastTurnoverDr;
				FieldsValues [ "B51" ] = FieldsValues [ "B51" ] + row.CurrentTurnoverDr;
			endif;
		endif;
		if ( row.Parent = "711"
			or row.Parent = "712"	
			or row.Parent = "713"
			or row.Parent = "714"
			or row.Parent = "715"
			or row.Parent = "716"
			or row.Parent = "717"
			or row.Parent = "718" ) then
			FieldsValues [ "A53" ] = FieldsValues [ "A53" ] + row.LastTurnoverDr;
			FieldsValues [ "B53" ] = FieldsValues [ "B53" ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "721"
			or row.Parent = "722"	
			or row.Parent = "723" ) then
			FieldsValues [ "A54" ] = FieldsValues [ "A54" ] + row.LastTurnoverDr;
			FieldsValues [ "B54" ] = FieldsValues [ "B54" ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "731" ) then
			FieldsValues [ "A57" ] = FieldsValues [ "A57" ] + row.LastTurnoverDr;
			FieldsValues [ "B57" ] = FieldsValues [ "B57" ] + row.CurrentTurnoverDr;
		endif;
		
		// *************
		// SITUAŢIA DE PROFIT ŞI PIERDERE
		// *************
		
		if ( row.Parent = "611" ) then
			i = "149";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverCr;
		endif;
		if ( row.Parent = "711" ) then
			i = "150";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "612"
			or row.Parent = "613"	
			or row.Parent = "616"
			or row.Parent = "617"
			or row.Parent = "618" ) then
			i = "152";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "712" ) then
			i = "153";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "713" ) then
			i = "154";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "714"
			or row.Parent = "715"
			or row.Parent = "716"
			or row.Parent = "717"
			or row.Parent = "718" ) then
			i = "155";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		i = "157";
		last = prefixLast + i;
		current = prefixCurrent + i;
		if ( row.Parent = "621"
			or row.Parent = "622"
			or row.Parent = "623" ) then
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverCr;
		endif;
		if ( row.Parent = "721"
			or row.Parent = "722"
			or row.Parent = "723" ) then
			FieldsValues [ last ] = FieldsValues [ last ] - row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] - row.CurrentTurnoverDr;
		endif;
		if ( row.Parent = "731" ) then
			i = "159";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastTurnoverDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentTurnoverDr;
		endif;
		
	enddo;
	
	// **********
	// Balance
	// **********
	prefixLast = "C";
	prefixCurrent = "D";
	
	prefixBegin = "C";
	prefixEnd = "F";
	prefixPlus = "D";
	prefixMinus = "E";
	
	for each row in Env.Balances do
		
		// **********
		// Activ
		// **********
		if ( row.Parent = "111"
			or row.Parent = "112"
			or row.Parent = "113"
			or row.Parent = "114" ) then
			FieldsValues [ "C71" ] = FieldsValues [ "C71" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D71" ] = FieldsValues [ "D71" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "121"
			or row.Parent = "127" ) then
			FieldsValues [ "C72" ] = FieldsValues [ "C72" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D72" ] = FieldsValues [ "D72" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "122"
			or row.Parent = "128" ) then
			FieldsValues [ "C73" ] = FieldsValues [ "C73" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D73" ] = FieldsValues [ "D73" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "123"
			or row.Parent = "124"
			or row.Parent = "129" ) then
			FieldsValues [ "C74" ] = FieldsValues [ "C74" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D74" ] = FieldsValues [ "D74" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "125"
			or row.Parent = "126" ) then
			FieldsValues [ "C75" ] = FieldsValues [ "C75" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D75" ] = FieldsValues [ "D75" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "131"
			or row.Parent = "132"
			or row.Parent = "133" ) then
			FieldsValues [ "C76" ] = FieldsValues [ "C76" ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ "D76" ] = FieldsValues [ "D76" ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		
		if ( row.Parent = "141" ) then
			i = "77";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "142" ) then
			i = "78";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "151"
			or row.Parent = "152" ) then
			i = "79";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "161"
			or row.Parent = "134" ) then
			i = "80";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "162" ) then
			i = "81";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "171"
			or row.Parent = "172" ) then
			i = "82";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "211" ) then
			i = "84";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "212" ) then
			i = "85";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "213"
			or row.Parent = "214" ) then
			i = "86";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "216"
			or row.Parent = "215" ) then
			i = "87";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "217" ) then
			i = "88";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "221"
			or row.Parent = "222" ) then
			i = "89";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "223" ) then
			i = "90";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "224" ) then
			i = "91";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "225" ) then
			i = "92";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "226" ) then
			i = "93";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "231"
			or row.Parent = "232"
			or row.Parent = "233"
			or row.Parent = "234" ) then
			i = "94";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "241"
			or row.Parent = "242"
			or row.Parent = "243"
			or row.Parent = "244" ) then
			i = "95";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "245"
			or row.Parent = "246" ) then
			i = "96";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "251" ) then
			i = "97";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "252" ) then
			i = "98";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "261"
			or row.Parent = "262"
			or row.Parent = "253" ) then
			i = "99";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceDr - row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr - row.CurrentBalanceCr;
		endif;
		
		// **********
		// Pasiv
		// **********
		
		if ( row.Parent = "311"
			or row.Parent = "312" ) then
			i = "102";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "321"
			or row.Parent = "322"
			or row.Parent = "323" ) then
			i = "103";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "331" ) then
			i = "104";
			current = prefixCurrent + i;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "332" ) then
			i = "105";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Code = "3331"
			or row.Code = "3332" ) then
			i = "106";
			current = prefixCurrent + i;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr - row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "334" ) then
			i = "107";
			current = prefixCurrent + i;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "335"
			or row.Parent = "341"
			or row.Parent = "342"
			or row.Parent = "343"
			or row.Parent = "313"
			or row.Parent = "314" ) then
			i = "108";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr - row.LastBalanceDr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr - row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "411" ) then
			i = "110";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "412" ) then
			i = "111";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "413" ) then
			i = "112";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "421"
			or row.Parent = "422"
			or row.Parent = "423"
			or row.Parent = "424"
			or row.Parent = "425"
			or row.Parent = "426"
			or row.Parent = "427"
			or row.Parent = "428"
			or row.Parent = "414" ) then
			i = "113";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "511" ) then
			i = "115";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "512" ) then
			i = "116";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "521" ) then
			i = "117";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "522" ) then
			i = "118";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "523" ) then
			i = "119";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "531"
			or row.Parent = "532" ) then
			i = "120";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "533" ) then
			i = "121";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "534" ) then
			i = "122";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "535" ) then
			i = "123";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "536" ) then
			i = "124";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "537" ) then
			i = "125";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "538" ) then
			i = "126";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "541"
			or row.Parent = "542"
			or row.Parent = "543"
			or row.Parent = "544"
			or row.Parent = "513" ) then
			i = "127";
			last = prefixLast + i;
			current = prefixCurrent + i;
			FieldsValues [ last ] = FieldsValues [ last ] + row.LastBalanceCr;
			FieldsValues [ current ] = FieldsValues [ current ] + row.CurrentBalanceCr;
		endif;
		
		// ***********
		// SITUAŢIA MODIFICĂRILOR CAPITALULUI PROPRIU
		// ***********
		
		if ( row.Parent = "311" ) then
			i = "169";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "312" ) then
			i = "170";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "313" ) then
			i = "171";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "314" ) then
			i = "172";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "315" ) then
			i = "173";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "321" ) then
			i = "175";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "322" ) then
			i = "176";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "323" ) then
			i = "177";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "331" ) then
			i = "179";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "332" ) then
			i = "180";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "333" ) then
			i = "181";
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "334" ) then
			i = "182";
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverDr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverCr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceDr;
		endif;
		if ( row.Parent = "335" ) then
			i = "183";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "341"
			or row.Parent = "342"
			or row.Parent = "343" ) then
			i = "185";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "343" ) then
			i = "186";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		if ( row.Parent = "342" ) then
			i = "187";
			begin = prefixBegin + i;
			end = prefixEnd + i;
			plus = prefixPlus + i;
			minus = prefixMinus + i;
			FieldsValues [ begin ] = FieldsValues [ begin ] + row.LastBalanceCr;
			FieldsValues [ plus ] = FieldsValues [ plus ] + row.TurnoverCr;
			FieldsValues [ minus ] = FieldsValues [ minus ] + row.TurnoverDr;
			FieldsValues [ end ] = FieldsValues [ end ] + row.CurrentBalanceCr;
		endif;
		
	enddo;
	
	assignField ( "A47", "Last", "_050" );
	assignField ( "B47", "Current", "_050" );
	
	~draw:
	
	area = getArea ();
	
	draw ();
	if ( not InternalProcessing ) then
		TabDoc.FitToPage = true;
	endif;
	
EndProcedure

Procedure Period ()
	
	result = Format ( DateStart, "L = 'ro_RO';DF='dd MMMM'" ) + " - " + Format ( DateEnd, "L = 'ro_RO';DF='dd MMMM'" );
	
EndProcedure

Procedure DateStart ()
	
	result = Format ( DateStart, "L = 'ro_RO';DF='dd MMMM yyyy'" );
	
EndProcedure

Procedure DateEnd ()
	
	result = Format ( DateEnd, "L = 'ro_RO';DF='dd MMMM yyyy'" );
	
EndProcedure

Procedure Year ()
	
	result = Format ( DateEnd, "DF='yyyy'" );
	
EndProcedure

Procedure Company ()
	
	result = Env.Fields.Company;
	
EndProcedure

Procedure CodeFiscal ()
	
	s = "| ";
	codeFiscal = Env.Fields.CodeFiscal;
	for i = 1 to 13 do
		char = Mid ( codeFiscal, i, 1 );
		if ( char = "" ) then
			char = " ";
		endif;	
		s = s + char + ? ( i = 13, " |", " | " );
	enddo;
	result = s;
	
EndProcedure

Procedure Accountant ()
	
	result = Env.Fields.Accountant;
	
EndProcedure

Procedure MobilePhone ()
	
	result = Env.Fields.MobilePhone;
	
EndProcedure

Procedure A46 ()
	
	result = sum ( "A43:A45" );
	
EndProcedure

Procedure B46 ()
	
	result = sum ( "B43:B45" );
	
EndProcedure

Procedure A55 ()
	
	result = sum ( "A47:A54" );
	
EndProcedure

Procedure B55 ()
	
	result = sum ( "B47:B54" );
	
EndProcedure

Procedure A56 ()
	
	result = get ( "A46" ) - get ( "A55" );
	
EndProcedure

Procedure B56 ()
	
	result = get ( "B46" ) - get ( "B55" );
	
EndProcedure

Procedure A58 ()
	
	result = get ( "A56" ) - get ( "A57" );
	
EndProcedure

Procedure B58 ()
	
	result = get ( "B56" ) - get ( "B57" );
	
EndProcedure

Procedure C83 ()
	
	result = sum ( "C71:C82" );
	
EndProcedure

Procedure D83 ()
	
	result = sum ( "D71:D82" );
	
EndProcedure

Procedure C100 ()
	
	result = sum ( "C84:C99" );
	
EndProcedure

Procedure D100 ()
	
	result = sum ( "D84:D99" );
	
EndProcedure

Procedure C101 ()
	
	result = get ( "C83" ) + get ( "C100" );
	
EndProcedure

Procedure D101 ()
	
	result = get ( "D83" ) + get ( "D100" );
	
EndProcedure

Procedure C109 ()
	
	result = get ( "C102" ) + get ( "C103" ) + get ( "C105" ) + get ( "C108" );
	
EndProcedure

Procedure D109 ()
	
	result = sum ( "D102:D106" ) - get ( "D107" ) + get ( "D108" );
	
EndProcedure

Procedure C114 ()
	
	result = sum ( "C110:C113" );
	
EndProcedure

Procedure D114 ()
	
	result = sum ( "D110:D113" );
	
EndProcedure

Procedure C128 ()
	
	result = sum ( "C115:C127" );
	
EndProcedure

Procedure D128 ()
	
	result = sum ( "D115:D127" );
	
EndProcedure

Procedure C129 ()
	
	result = get ( "C109" ) + get ( "C114" ) + get ( "C128" );
	
EndProcedure

Procedure D129 ()
	
	result = get ( "D109" ) + get ( "D114" ) + get ( "D128" );
	
EndProcedure

Procedure C151 ()
	
	result = get ( "C149" ) - get ( "C150" );
	
EndProcedure

Procedure D151 ()
	
	result = get ( "D149" ) - get ( "D150" );
	
EndProcedure

Procedure C156 ()
	
	result = sum ( "C151:C152" ) - sum ( "C153:C155" );
	
EndProcedure

Procedure D156 ()
	
	result = sum ( "D151:D152" ) - sum ( "D153:D155" );
	
EndProcedure

Procedure C158 ()
	
	result = sum ( "C156:C157" );
	
EndProcedure

Procedure D158 ()
	
	result = sum ( "D156:D157" );
	
EndProcedure

Procedure C160 ()
	
	result = get ( "C158" ) - get ( "C159" );
	
EndProcedure

Procedure D160 ()
	
	result = get ( "D158" ) - get ( "D159" );
	
EndProcedure

Procedure C174 ()
	
	result = sum ( "C169:C173" );
	
EndProcedure

Procedure D174 ()
	
	result = sum ( "D169:D173" );
	
EndProcedure

Procedure E174 ()
	
	result = sum ( "E169:E173" );
	
EndProcedure

Procedure F174 ()
	
	result = sum ( "F169:F173" );
	
EndProcedure

Procedure C178 ()
	
	result = sum ( "C175:C177" );
	
EndProcedure

Procedure D178 ()
	
	result = sum ( "D175:D177" );
	
EndProcedure

Procedure E178 ()
	
	result = sum ( "E175:E177" );
	
EndProcedure

Procedure F178 ()
	
	result = sum ( "F175:F177" );
	
EndProcedure

Procedure C184 ()
	
	result = sum ( "C179:C180" ) + get ( "C183" );
	
EndProcedure

Procedure D184 ()
	
	result = sum ( "D179:D183" );
	
EndProcedure

Procedure E184 ()
	
	result = sum ( "E179:E183" );
	
EndProcedure

Procedure F184 ()
	
	result = sum ( "F179:F183" );
	
EndProcedure

Procedure C188 ()
	
	result = get ( "C174" ) + get ( "C178" ) + sum ( "C184:C185" );
	
EndProcedure

Procedure D188 ()
	
	result = get ( "D174" ) + get ( "D178" ) + sum ( "D184:D185" );
	
EndProcedure

Procedure E188 ()
	
	result = get ( "E174" ) + get ( "E178" ) + sum ( "E184:E185" );
	
EndProcedure

Procedure F188 ()
	
	result = get ( "F174" ) + get ( "F178" ) + sum ( "F184:F185" );
	
EndProcedure

Procedure A207 ()
	
	result = get ( "A200" ) - sum ( "A201:A204" ) +  get ( "A205" ) - get ( "A206" ) ;
	
EndProcedure

Procedure B207 ()
	
	result = get ( "B200" ) - sum ( "B201:B204" ) +  get ( "B205" ) - get ( "B206" ) ;
	
EndProcedure

Procedure A213 ()
	
	result = get ( "A208" ) - get ( "A209" ) + sum ( "A210:A212" );
	
EndProcedure

Procedure B213 ()
	
	result = get ( "B208" ) - get ( "B209" ) + sum ( "B210:B212" );
	
EndProcedure

Procedure A219 ()
	
	result = get ( "A214" ) - sum ( "A215:A216" ) + sum ( "A217:A218" );
	
EndProcedure

Procedure B219 ()
	
	result = get ( "B214" ) - sum ( "B215:B216" ) + sum ( "B217:B218" );
	
EndProcedure

Procedure A220 ()
	
	result = get ( "A207" ) + get ( "A213" ) + get ( "A219" );
	
EndProcedure

Procedure B220 ()
	
	result = get ( "B207" ) + get ( "B213" ) + get ( "B219" );
	
EndProcedure

Procedure A223 ()
	
	result = sum ( "A220:A222" );
	
EndProcedure

Procedure B223 ()
	
	result = sum ( "B220:B222" );
	
EndProcedure

