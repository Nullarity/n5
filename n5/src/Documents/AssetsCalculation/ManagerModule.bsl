#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then
	
Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	DocumentPresentation.StandardFields ( Fields, StandardProcessing );

EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	DocumentPresentation.StandardPresentation ( Metadata.Documents.AssetsCalculation.Synonym, Data, Presentation, StandardProcessing );
	
EndProcedure

Function CheckDate ( Ref, Date ) export 
	
	s = "
	|select top 1 Documents.Date as Date, presentation ( Documents.Ref ) as Ref
	|from Document.AssetsCalculation as Documents
	|where endOfPeriod ( Documents.Date, month ) = endOfPeriod ( &Date, month )
	|and Documents.Posted 
	|";
	q = new Query ();
	if ( not Ref.IsEmpty () ) then
		s = s + " and Documents.Ref <> &Ref ";
		q.SetParameter ( "Ref", Ref ); 
	endif; 
	q.SetParameter ( "Date", Date );
	q.Text = s;
	table = q.Execute ().Unload ();
	if ( table.Count () = 0 ) then
		return true;	
	else	
		row = table [ 0 ];
		p = new Structure ( "Date, Ref", Format ( row.Date, "DLF=D" ), row.Ref );
		Output.AssetsCalculationPeriod ( p );	
		return false;
	endif;
	
EndFunction

#region Posting

Function Post ( Env ) export
	
	getData ( Env );
	makeMovements ( Env );
	flagRegisters ( Env );
	return true;
	
EndFunction

Procedure getData ( Env )

	sqlFields ( Env );
	getFields ( Env );
	sqlLocations ( Env );
	sqlBalances ( Env );
	sqlBalancesBegin ( Env );
	sqlAssets ( Env );
	sqlShedules ( Env );
	sqlExpenses ( Env );
	getTables ( Env );
	Env.Insert ( "RateThisMonth", "Rate" + Month ( Env.Fields.Date ) );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Company as Company, Documents.PointInTime as Timestamp
	|from Document.AssetsCalculation as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure getFields ( Env )
	
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlLocations ( Env )
	
	s = "
	|// Assets 
	|select Amortization.Asset as Asset, Amortization.Acceleration as Acceleration, Amortization.Expenses as Expenses, 
	|	Amortization.LiquidationValue as LiquidationValue, 
	|	case when Amortization.Method = value ( Enum.Amortization.Linear ) then true else false end as Linear,
	|	case when Amortization.Method = value ( Enum.Amortization.Cumulative ) then true else false end as Cumulative, 
	|	case when Amortization.Method = value ( Enum.Amortization.Decreasing ) then true else false end as Decreasing, 
	|	Amortization.Schedule as Schedule, Amortization.UsefulLife as UsefulLife, Amortization.Starting as Starting, 
	|	dateadd ( dateadd ( endofperiod ( Amortization.Starting ), month, Amortization.UsefulLife ), day, - 1 ) as EndAmortization,
	|	Amortization.Asset.Account as Account, Amortization.Asset.DepreciationAccount as AmortizationAccount, true as FixedAsset
	|into Assets  
	|from InformationRegister.Depreciation.SliceLast ( &Timestamp, &Period >= Starting ) as Amortization 
	|where Amortization.Charge
	|union all
	|select Amortization.Asset, Amortization.Acceleration,	Amortization.Expenses, 0, 
	|	case when Amortization.Method = value ( Enum.Amortization.Linear ) then true else false end,
	|	case when Amortization.Method = value ( Enum.Amortization.Cumulative ) then true else false end, 
	|	case when Amortization.Method = value ( Enum.Amortization.Decreasing ) then true else false end, 
	|	value ( Catalog.DepreciationSchedules.EmptyRef ), Amortization.UsefulLife, Amortization.Starting,
	|	dateadd ( dateadd ( endofperiod ( Amortization.Starting ), month, Amortization.UsefulLife ), day, - 1 ), Amortization.Asset.Account,
	|	Amortization.Asset.AmortizationAccount, false 
	|from InformationRegister.Amortization.SliceLast ( &Timestamp, &Period >= Starting ) as Amortization
	|where Amortization.Charge
	|index by Asset, Account, AmortizationAccount
	|;
	|// Locations
	|select Locations.Asset as Asset, Locations.Department as Department
	|into Locations
	|from InformationRegister.FixedAssetsLocation.SliceLast ( &Timestamp, Asset in ( select Asset from Assets where FixedAsset ) ) as Locations
	|union all
	|select Locations.Asset, Locations.Department
	|from InformationRegister.IntangibleAssetsLocation.SliceLast ( &Timestamp, Asset in ( select Asset from Assets where not FixedAsset ) ) as Locations
	|index by Asset
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlBalances ( Env )
	
	s = "
	|// Balances of deprecation
	|select Balances.ExtDimension1 as Asset, -Balances.AmountBalance as Amount, Balances.Account as Account
	|into AmortizationBalances
	|from AccountingRegister.General.Balance ( &Timestamp, Account in ( select distinct AmortizationAccount from Assets where FixedAsset ), 
	|					value ( ChartOfCharacteristicTypes.Dimensions.FixedAssets ), ExtDimension1 in ( select Asset from Assets where FixedAsset ) 
	|					and Company = &Company ) as Balances
	|union all
	|select Balances.ExtDimension1, -Balances.AmountBalance, Balances.Account
	|from AccountingRegister.General.Balance ( &Timestamp, Account in ( select distinct AmortizationAccount from Assets where not FixedAsset ), 
	|					value ( ChartOfCharacteristicTypes.Dimensions.IntangibleAssets ), ExtDimension1 in ( select Asset from Assets where not FixedAsset )
	|					and Company = &Company ) as Balances
	|index by Account
	|;
	|// Balances of assets
	|select Balances.ExtDimension1 as Asset, Balances.AmountBalance as Amount, Balances.Account as Account
	|into AssetsBalances
	|from AccountingRegister.General.Balance ( &Timestamp, Account in ( select distinct Account from Assets where FixedAsset ),
	|					value ( ChartOfCharacteristicTypes.Dimensions.FixedAssets ), ExtDimension1 in ( select Asset from Assets where FixedAsset )
	|					and Company = &Company ) as Balances
	|union all
	|select Balances.ExtDimension1, Balances.AmountBalance, Balances.Account
	|from AccountingRegister.General.Balance ( &Timestamp, Account in ( select distinct Account from Assets where not FixedAsset ),
	|					value ( ChartOfCharacteristicTypes.Dimensions.IntangibleAssets ), ExtDimension1 in ( select Asset from Assets where not FixedAsset )
	|					and Company = &Company ) as Balances
	|where Balances.AmountBalance > 0
	|index by Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlBalancesBegin ( Env )
	
	s = "
	|// Balances of deprecation begin
	|select Balances.ExtDimension1 as Asset, -Balances.AmountBalance as Amount, Balances.Account as Account
	|into AmortizationBalancesBegin
	|from AccountingRegister.General.Balance ( &TimestampBegin, Account in ( select distinct AmortizationAccount from Assets where FixedAsset and Decreasing ), 
	|					value ( ChartOfCharacteristicTypes.Dimensions.FixedAssets ), ExtDimension1 in ( select Asset from Assets where FixedAsset and Decreasing ) 
	|					and Company = &Company ) as Balances
	|union all
	|select Balances.ExtDimension1, -Balances.AmountBalance, Balances.Account
	|from AccountingRegister.General.Balance ( &TimestampBegin, Account in ( select distinct AmortizationAccount from Assets where not FixedAsset and Decreasing ), 
	|					value ( ChartOfCharacteristicTypes.Dimensions.IntangibleAssets ), ExtDimension1 in ( select Asset from Assets where not FixedAsset and Decreasing )
	|					and Company = &Company ) as Balances
	|index by Account
	|;
	|// Balances of assets begin
	|select Balances.ExtDimension1 as Asset, Balances.AmountBalance as Amount, Balances.Account as Account
	|into AssetsBalancesBegin
	|from AccountingRegister.General.Balance ( &TimestampBegin, Account in ( select distinct Account from Assets where FixedAsset and Decreasing ),
	|					value ( ChartOfCharacteristicTypes.Dimensions.FixedAssets ), ExtDimension1 in ( select Asset from Assets where FixedAsset and Decreasing )
	|					and Company = &Company ) as Balances
	|union all
	|select Balances.ExtDimension1, Balances.AmountBalance, Balances.Account
	|from AccountingRegister.General.Balance ( &TimestampBegin, Account in ( select distinct Account from Assets where not FixedAsset and Decreasing ),
	|					value ( ChartOfCharacteristicTypes.Dimensions.IntangibleAssets ), ExtDimension1 in ( select Asset from Assets where not FixedAsset and Decreasing )
	|					and Company = &Company ) as Balances
	|index by Account
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlAssets ( Env )
	
	s = "
	|// #Assets
	|select Assets.Asset as Asset, case when Assets.Acceleration = 0 then 1 else Assets.Acceleration end as Acceleration, 
	|	Assets.AmortizationAccount as AmortizationAccount, Assets.Expenses as Expenses, 
	|	Assets.LiquidationValue as LiquidationValue, Assets.Linear as Linear, Assets.Cumulative as Cumulative, Assets.Starting as Starting,
	|	Assets.Decreasing as Decreasing, Assets.UsefulLife as UsefulLife, Assets.Schedule as Schedule, 
	|	Locations.Department as Department, isnull ( AssetsBalances.Amount, 0 ) - Assets.LiquidationValue as Basis,
	|	AssetsBalances.Amount - isnull ( AmortizationBalances.Amount, 0 ) as Balance,
	|	AssetsBalances.Amount - isnull ( AmortizationBalances.Amount, 0 ) - Assets.LiquidationValue as Limit,
	|	case when Assets.Schedule = value ( Catalog.DepreciationSchedules.EmptyRef ) then false else true end as UseShedule,
	|	case when year ( Assets.EndAmortization ) = year ( &Period ) then true else false end as LastYear,
	|	Assets.EndAmortization as EndAmortization,
	|	( datediff ( &Period, Assets.EndAmortization, month ) + 1 ) / 12 as YearsLeft,
	|	( datediff ( Assets.Starting, Assets.EndAmortization, month ) + 1 ) / 12 as Years,
	|	datediff ( &Period, dateadd ( Assets.Starting, month, Assets.UsefulLife ), month ) as MonthsLeft,
	|	case when Assets.EndAmortization = &Period then true else false end as LastMonth,
	|	case when year ( Assets.Starting ) = year ( &Period ) then AssetsBalances.Amount 
	|		 else isnull ( AssetsBalancesBegin.Amount, 0 ) - isnull ( AmortizationBalancesBegin.Amount, 0 ) 
	|	end as BalanceBegin,
	|	case when Assets.FixedAsset then value ( Enum.Operations.FixedAssetsDepreciation ) else value ( Enum.Operations.IntangibleAssetsAmortization ) 
	|	end as Operation 
	|from Assets as Assets
	|	//
	|	// Locations
	|	//
	|	left join Locations as Locations
	|	on Locations.Asset = Assets.Asset
	|	//
	|	// AmortizationBalancesBegin
	|	//
	|	left join AmortizationBalancesBegin as AmortizationBalancesBegin
	|	on AmortizationBalancesBegin.Asset = Assets.Asset
	|	and AmortizationBalancesBegin.Account = Assets.AmortizationAccount
	|	//
	|	// AssetsBalancesBegin
	|	//
	|	left join AssetsBalancesBegin as AssetsBalancesBegin
	|	on AssetsBalancesBegin.Asset = Assets.Asset
	|	and AssetsBalancesBegin.Account = Assets.Account
	|	//
	|	// AmortizationBalances
	|	//
	|	left join AmortizationBalances as AmortizationBalances
	|	on AmortizationBalances.Asset = Assets.Asset
	|	and AmortizationBalances.Account = Assets.AmortizationAccount
	|	//
	|	// AssetsBalances
	|	//
	|	join AssetsBalances as AssetsBalances
	|	on AssetsBalances.Asset = Assets.Asset
	|	and AssetsBalances.Account = Assets.Account
	|where case when AssetsBalances.Amount - Assets.LiquidationValue <= 0 or Assets.UsefulLife = 0 then false else true end
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlShedules ( Env )
	
	s = "
	|// #Schedules
	|select Schedules.Ref as Schedule, Schedules.Rate1 as Rate1, Schedules.Rate2 as Rate2, Schedules.Rate3 as Rate3, Schedules.Rate4 as Rate4,
	|	Schedules.Rate5 as Rate5, Schedules.Rate6 as Rate6, Schedules.Rate7 as Rate7, Schedules.Rate8 as Rate8, Schedules.Rate9 as Rate9,
	| 	Schedules.Rate10 as Rate10, Schedules.Rate11 as Rate11, Schedules.Rate12 as Rate12
	|from Catalog.DepreciationSchedules as Schedules
	|where Schedules.Ref in ( select distinct Schedule from Assets where FixedAsset ) 
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure sqlExpenses ( Env )
	
	s = "
	|// #Expenses 
	|select Expenses.Ref as Expenses, Expenses.Expense as Expense, Expenses.Account as Account, Expenses.Rate as Rate
	|from Catalog.ExpenseMethods.Expenses as Expenses
	|where Expenses.Ref in ( select distinct Assets.Expenses from Assets as Assets ) 
	|";
	Env.Selection.Add ( s );
	
EndProcedure 

Procedure getTables ( Env )
	
	fields = Env.Fields;
	q = Env.Q;
	q.SetParameter ( "Company", fields.Company );
	date = fields.Date;
	q.SetParameter ( "Period", date );
	q.SetParameter ( "Timestamp", fields.Timestamp );
	q.SetParameter ( "TimestampBegin", new Boundary ( BegOfYear ( date ) - 1, BoundaryType.Including ) );
	SQL.Prepare ( Env );
	Env.Insert ( "Data", q.ExecuteBatch () );
	SQL.Unload ( Env, Env.Data );
	
EndProcedure

Procedure makeMovements ( Env ) 

	table = Env.Assets;
	if ( table.Count () = 0 ) then
		return;
	endif;
	expenses = Env.Expenses;
	filter = new Structure ( "Expenses" );
	p = GeneralRecords.GetParams ();
	fields = Env.Fields;
	p.Date = fields.Date;
	p.Company = fields.Company;
	p.Recordset = Env.Registers.General;
	for each row in table do
		amount = getAmount ( Env, row );
		if ( amount = 0 ) then
			continue;
		endif;
		p.Operation = row.Operation;	
		p.AccountCr = row.AmortizationAccount;
		p.DimCr1 = row.Asset;
		p.DimDr2 = row.Department;
		filter.Expenses = row.Expenses;
		rows = expenses.Copy ( filter );
		totalRate = rows.Total ( "Rate" );
		for each rowExpense in rows do
			p.AccountDr = rowExpense.Account;
			p.DimDr1 = rowExpense.Expense;
			coefficient = rowExpense.Rate / totalRate;
			p.Amount = amount * coefficient;
			GeneralRecords.Add ( p );	
		enddo;
	enddo;

EndProcedure

Function getAmount ( Env, Data ) 

	if ( Data.LastMonth ) then
		return Data.Limit;
	else
		if ( Data.Linear ) then
			amount = amountLinear ( Env, Data );
		elsif ( Data.Cumulative ) then
			amount = amountCumulative ( Env, Data );
		elsif ( Data.Decreasing ) then
			amount = amountDecreasing ( Env, Data ); 
		else
			amount = 0;
		endif;
		return Min ( amount, Data.Limit );
	endif;

EndFunction

Function amountLinear ( Env, Data )
	
	if ( Data.UseShedule ) then
		coefficient = coefficientSchedule ( Env, Data );
		if ( coefficient = 0 ) then
			return 0;
		else
			return ( Data.Basis / Data.Years ) * coefficient;
		endif;
	else
		return Data.Basis / Data.UsefulLife;	
	endif;
	
EndFunction

Function coefficientSchedule ( Env, Data )
	
	scheduleRow = Env.Schedules.Find ( Data.Schedule, "Schedule" );
	totalRate = 0;
	for i = 1 to 12 do
		totalRate = totalRate + scheduleRow [ "Rate" + i ];
	enddo;
	return ? ( totalRate = 0, 0, scheduleRow [ Env.RateThisMonth ] / totalRate );
	
EndFunction 

Function amountCumulative ( Env, Data )
	
	years = 0;
	for i = 1 to Data.Years do
		years = years + i;				
	enddo;
	return ( Data.YearsLeft / years ) * Data.Basis / monthsThisYear ( Env, Data ); 
	
EndFunction

Function monthsThisYear ( Env, Data ) 

	if ( Data.LastYear ) then
		if ( Data.Years = 1 ) then
			return Data.UsefulLife;
		else
			return Month ( Data.EndAmortization );
		endif;
	else
		begin = Data.Starting;
		if ( Year ( begin ) = Year ( Env.Fields.Date ) ) then
			return 12 - Month ( begin ) + 1;
		else
			return 12;
		endif;
	endif;

EndFunction

Function amountDecreasing ( Env, Data )
	
	if ( Data.LastYear ) then
		return ( Data.Balance - Data.LiquidationValue ) / Data.MonthsLeft;
	else
		if ( Data.UseShedule ) then
			coefficient = coefficientSchedule ( Env, Data );
			if ( coefficient = 0 ) then
				return 0;
			else
				return ( Data.BalanceBegin / Data.Years ) * Data.Acceleration * coefficient;
			endif;
		else
			return ( Data.BalanceBegin / Data.UsefulLife ) * Data.Acceleration;
		endif; 
	endif;
	
EndFunction 

Procedure flagRegisters ( Env )
	
	Env.Registers.General.Write = true;
	
EndProcedure

#endregion

#endif