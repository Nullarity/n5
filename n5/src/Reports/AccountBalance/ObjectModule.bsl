#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Params export;
var AccountFilter;
var AccountData;
var AccountGroup;
var LastGroup;
var ShowCurrency;
var ShowQuantity;
var DimsHierarchy;
var ShowDimensions;

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
	hideParams ();
	readGroup ();
	filterByAccount ();
	setAccountsHierarchy ();
	setResources ();
	addCurrency ();
	addDims ();
	addRecorders ();
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
	
EndProcedure 

Procedure hideParams ()
	
	list = Params.HiddenParams;
	list.Add ( "Period" );
	list.Add ( "Account" );
	list.Add ( "AccountsHierarchy" );
	list.Add ( "ShowDimensions" );
	list.Add ( "DimsHierarchy" );
	list.Add ( "ShowCurrency" );
	list.Add ( "ShowQuantity" );
	list.Add ( "ShowRecorders" );
	
EndProcedure 

Procedure readGroup ()
	
	AccountGroup = DCsrv.GetGroup ( Params.Settings, "Account" );
	
EndProcedure

Procedure filterByAccount ()
	
	DC.SetParameter ( Params.Settings, "Account", AccountFilter );
	if ( AccountData.Fields.Main ) then
		set = Params.Schema.DataSets;
		changeQuery ( set.DataSet1 );
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
		if ( AccountData.Fields.Main ) then
			group.GroupType = DataCompositionGroupType.HierarchyOnly;
		else
			group.GroupType = DataCompositionGroupType.Items;
		endif;
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
	
EndProcedure

Procedure setUsage ( Fields, Flag )
	
	selection = Params.Settings.Selection;
	for each field in fields do
		DCsrv.GetField ( selection, field ).Use = Flag;
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
	ShowDimensions = p.Use and ValueIsFilled ( deep );
	if ( not ShowDimensions ) then
		return;
	endif; 
	dims = GeneralAccounts.DimensionsByLevel ( deep, AccountData );
	level = dims.Count ();
	if ( level = 0 ) then
		return;
	endif;
	groupType = ? ( DimsHierarchy, DataCompositionGroupType.Hierarchy, DataCompositionGroupType.Items );
	fields = Params.Schema.DataSets.DataSet1.Fields;
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

Procedure addRecorders ()
	
	settings = Params.Settings;
	p = DC.GetParameter ( settings, "ShowRecorders" );
	if ( not ( p.Value and p.Use ) ) then
		return;
	endif; 
	recorders = DCsrv.GetGroup ( settings, "Recorder" );
	if ( ShowDimensions
		or AccountData.Fields.Level = 0 ) then
		dimension = DCsrv.GetField ( recorders.Selection, "Dim1" );
		dimension.Use = false;
	endif; 
	LastGroup = DCsrv.Insert ( recorders, LastGroup.Structure );
	LastGroup.Use = true;
	
EndProcedure

Procedure titleReport ()
	
	period = DC.FindParameter ( Params.Composer, "Period" );
	Reports.BalanceSheet.SetTitle ( Params, period, AccountFilter );
	
EndProcedure 

#endif