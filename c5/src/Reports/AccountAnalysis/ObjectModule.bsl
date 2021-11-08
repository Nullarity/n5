#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;
var AccountData;
var AccountGroup;
var LastGroup;
var BalancedAccountGroup;
var ShowCurrency;
var ShowQuantity;
var DimsHierarchy;
var BalancedDimsLevel;

Procedure OnCheck ( Cancel ) export
	
	getAccount ();
	if ( not checkAccount () ) then
		Cancel = true;
	endif; 
	
EndProcedure 

Procedure getAccount ()
	
	filter = DC.FindParameter ( Params.Composer, "Account" );
	AccountFilter = filter.Value;
	AccountData = GeneralAccounts.GetData ( AccountFilter );
	
EndProcedure 

Function checkAccount ()
	
	if ( ValueIsFilled ( AccountFilter ) ) then
		return true;
	endif;
	Output.FieldIsEmpty ( new Structure ( "Field", Params.Schema.Parameters.Account.Title ) );
	return false;

EndFunction 

Procedure OnCompose () export

	readParams ();
	readGroups ();
	hideParams ();
	filterByAccount ();
	setAccountsHierarchy ();
	setResources ();
	addCurrency ();
	addDims ();
	addBalancedAccount ();
	titleReport ();
	
EndProcedure

Procedure readParams ()
	
	settings = Params.Settings;
	p = DC.GetParameter ( settings, "ShowCurrency" );
	ShowCurrency = p.Use and p.Value;
	p = DC.GetParameter ( settings, "ShowQuantity" );
	ShowQuantity = p.Use and p.Value;
	p = DC.GetParameter ( Params.Settings, "DimsHierarchy" );
	DimsHierarchy = p.Use and p.Value;
	p = DC.GetParameter ( Params.Settings, "ShowBalancedDimensions" );
	deep = p.Value;
	if ( not ( p.Use and ValueIsFilled ( deep ) ) ) then
		BalancedDimsLevel = 0;
	else
		BalancedDimsLevel = GeneralAccounts.LevelDeep ( deep );
	endif; 
	
EndProcedure 

Procedure readGroups ()
	
	settings = Params.Settings;
	AccountGroup = DCsrv.GetGroup ( settings, "Account" );
	BalancedAccountGroup = DCsrv.GetGroup ( settings, "BalancedAccount" );
	
EndProcedure

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	list.Add ( "Account" );
	list.Add ( "AccountsHierarchy" );
	list.Add ( "ShowDimensions" );
	list.Add ( "ShowBalancedDimensions" );
	list.Add ( "DimsHierarchy" );
	list.Add ( "ShowCurrency" );
	list.Add ( "ShowQuantity" );
	
EndProcedure 

Procedure filterByAccount ()
	
	DC.SetParameter ( Params.Settings, "Account", AccountFilter );
	if ( AccountData.Fields.Main ) then
		set = Params.Schema.DataSets;
		changeQuery ( set.Balances );
		changeQuery ( set.Turnovers );
	endif; 
	
EndProcedure

Procedure changeQuery ( Source )

	Source.Query = StrReplace ( Source.Query, "Account = &Account", "Account in hierarchy ( &Account )" );

EndProcedure

Procedure setAccountsHierarchy ()
	
	group = DCsrv.FindField ( AccountGroup, "Account" );
	p = DC.FindParameter ( Params.Settings, "AccountsHierarchy" );
	if ( p.Use
		and p.Value ) then
		group.GroupType = DataCompositionGroupType.Hierarchy;
	else
		group.GroupType = DataCompositionGroupType.Items;
	endif; 

EndProcedure

Procedure setResources ()
	
	fields = new Array ();
	fields.Add ( "CurrencyAmountOpeningBalanceDr" );
	fields.Add ( "CurrencyAmountOpeningBalanceCr" );
	fields.Add ( "CurrencyAmountClosingBalanceDr" );
	fields.Add ( "CurrencyAmountClosingBalanceCr" );
	fields.Add ( "CurrencyAmountTurnoverDr" );
	fields.Add ( "CurrencyAmountTurnoverCr" );
	setUsage ( fields, ShowCurrency );
	fields.Clear ();
	fields.Add ( "QuantityOpeningBalanceDr" );
	fields.Add ( "QuantityOpeningBalanceCr" );
	fields.Add ( "QuantityClosingBalanceDr" );
	fields.Add ( "QuantityClosingBalanceCr" );
	fields.Add ( "QuantityTurnoverDr" );
	fields.Add ( "QuantityTurnoverCr" );
	setUsage ( fields, ShowQuantity );
	fields.Clear ();
	fields.Add ( "CurrencyAmountDr" );
	fields.Add ( "CurrencyAmountCr" );
	requireFields ( fields, ShowCurrency );
	fields.Clear ();
	fields.Add ( "QuantityDr" );
	fields.Add ( "QuantityCr" );
	requireFields ( fields, ShowQuantity );
	
EndProcedure

Procedure setUsage ( Fields, Flag )
	
	selection = Params.Settings.Selection;
	balanced = BalancedAccountGroup.Selection;
	for each field in fields do
		DCsrv.GetField ( selection, field ).Use = Flag;
		DCsrv.GetField ( balanced, field ).Use = Flag;
	enddo; 
	
EndProcedure 

Procedure requireFields ( Fields, Flag )
	
	list = Params.Schema.DataSets.Turnovers.Fields;
	for each field in fields do
		list.Find ( field ).Role.Required = Flag;
	enddo; 
	
EndProcedure 

Procedure addCurrency ()
	
	if ( not ShowCurrency ) then
		LastGroup = AccountGroup;
		return;
	endif; 
	LastGroup = AccountGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
	field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
	field.Use = true;
	field.Field = new DataCompositionField ( "Currency" );
	field.GroupType = DataCompositionGroupType.Items;
	LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
	LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
	
EndProcedure

Procedure addDims ()
	
	p = DC.GetParameter ( Params.Settings, "ShowDimensions" );
	deep = p.Value;
	if ( not ( p.Use and ValueIsFilled ( deep ) ) ) then
		return;
	endif;
	dims = GeneralAccounts.DimensionsByLevel ( deep, AccountData );
	level = dims.Count ();
	if ( level = 0 ) then
		return;
	endif;
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.Balances.Fields;
	accountDims = AccountData.Dims;
	for each dim in dims do
		i = dim.Position;
		LastGroup = LastGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
		field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
		field.Use = true;
		field.Field = new DataCompositionField ( "Dim" + i );
		field.GroupType = groupType;
		LastGroup.Selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
		LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
		field = fields.Find ( "Dim" + i );
		field.Title = "" + accountDims [ i - 1 ].Presentation;
	enddo; 
	
EndProcedure

Procedure addBalancedAccount ()
	
	LastGroup = DCsrv.Insert ( BalancedAccountGroup, LastGroup.Structure );
	LastGroup.Use = true;
	LastGroup.Selection.Items [ 0 ].Title = "#hideCell";
	addBalancedDims ();
	
EndProcedure 

Procedure addBalancedDims ()

	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	for i = 1 to BalancedDimsLevel do
		name = "BalancedDim" + i;
		dataField = new DataCompositionField ( name );
		LastGroup = LastGroup.Structure.Add ( Type ( "DataCompositionGroup" ) );
		LastGroup.Name = name;
		field = LastGroup.GroupFields.Items.Add ( Type ( "DataCompositionGroupField" ) );
		field.Use = true;
		field.Field = dataField;
		field.GroupType = groupType;
		selection = LastGroup.Selection;
		field = selection.Items.Add ( Type ( "DataCompositionSelectedField" ) );
		field.Field = dataField;
		field.Title = "#hideCell";
		selection.Items.Add ( Type ( "DataCompositionAutoSelectedField" ) );
		LastGroup.Order.Items.Add ( Type ( "DataCompositionAutoOrderItem" ) );
	enddo; 
	
EndProcedure

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	Reports.BalanceSheet.SetTitle ( Params, period, AccountFilter );
	
EndProcedure 

Procedure OnPrepare ( Template ) export
	
	fixExpressions ( Template );
	
EndProcedure 

Procedure fixExpressions ( Template )
	
	dims = new Array ();
	dims.Add ( "BalancedAccount" );
	for i = 1 to BalancedDimsLevel do
		dims.Add ( "BalancedDim" + i );
	enddo;
	for each dim in dims do
		definition = Reporter.FindDefinition ( Template, dim );
		Reporter.ReplaceExpression ( definition, "Balances.AmountOpeningBalanceDr", "0" );
		Reporter.ReplaceExpression ( definition, "Balances.AmountOpeningBalanceCr", "0" );
		Reporter.ReplaceExpression ( definition, "Balances.AmountClosingBalanceDr", "0" );
		Reporter.ReplaceExpression ( definition, "Balances.AmountClosingBalanceCr", "0" );
		Reporter.ReplaceExpression ( definition, "Balances.AmountTurnoverDr", "Turnovers.AmountDr" );
		Reporter.ReplaceExpression ( definition, "Balances.AmountTurnoverCr", "Turnovers.AmountCr" );
		if ( ShowCurrency ) then
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountOpeningBalanceDr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountOpeningBalanceCr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountClosingBalanceDr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountClosingBalanceCr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountTurnoverCr", "Turnovers.CurrencyAmountCr" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountTurnoverDr", "Turnovers.CurrencyAmountDr" );
			Reporter.ReplaceExpression ( definition, "Balances.CurrencyAmountTurnoverCr", "Turnovers.CurrencyAmountCr" );
		endif; 
		if ( ShowQuantity ) then
			Reporter.ReplaceExpression ( definition, "Balances.QuantityOpeningBalanceDr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.QuantityOpeningBalanceCr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.QuantityClosingBalanceDr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.QuantityClosingBalanceCr", "0" );
			Reporter.ReplaceExpression ( definition, "Balances.QuantityTurnoverDr", "Turnovers.QuantityDr" );
			Reporter.ReplaceExpression ( definition, "Balances.QuantityTurnoverCr", "Turnovers.QuantityCr" );
		endif; 
	enddo; 
	
EndProcedure 

#endif