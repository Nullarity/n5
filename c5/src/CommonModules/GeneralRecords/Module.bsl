
Function GetParams () export
	
	p = new Structure (
		"Date,
		|Company,
		|AccountDr,
		|AccountCr,
		|Amount,
		|Operation,
		|Content,
		|QuantityDr,
		|QuantityCr,
		|CurrencyDr,
		|CurrencyCr,
		|CurrencyAmountDr,
		|CurrencyAmountCr,
		|DimDr1,
		|DimCr1,
		|DimDr1Type,
		|DimCr1Type,
		|DimDr2,
		|DimCr2,
		|DimDr2Type,
		|DimCr2Type,
		|DimDr3,
		|DimCr3,
		|DimDr3Type,
		|DimCr3Type,
		|Dependency,
		|Recordset,
		|DataDr,
		|DataCr,
		|Advance,
		|AdvancesRecordset"
	);
	return p;

EndFunction

Function Frame () export
	
	return AccountingRegisters.General.CreateRecordSet ().UnloadColumns ();
	
EndFunction 

Function Add ( Params ) export
	
	#region DataInit
	var quantityDr;
	var currencyDr;
	var currencyAmountDr;
	var quantityCr;
	var currencyCr;
	var currencyAmountCr;
	var content;
	var dimDr1;
	var dimDr1Type;
	var dimDr2;
	var dimDr2Type;
	var dimDr3;
	var dimDr3Type;
	var dimCr1;
	var dimCr1Type;
	var dimCr2;
	var dimCr2Type;
	var dimCr3;
	var dimCr3Type;
	Params.Property ( "QuantityDr", quantityDr );
	Params.Property ( "QuantityCr", quantityCr );
	Params.Property ( "CurrencyDr", currencyDr );
	Params.Property ( "CurrencyCr", currencyCr );
	Params.Property ( "CurrencyAmountDr", currencyAmountDr );
	Params.Property ( "CurrencyAmountCr", currencyAmountCr );
	Params.Property ( "Content", content );
	Params.Property ( "DimDr1", dimDr1 );
	Params.Property ( "DimDr1Type", dimDr1Type );
	Params.Property ( "DimDr2", dimDr2 );
	Params.Property ( "DimDr2Type", dimDr2Type );
	Params.Property ( "DimDr3", dimDr3 );
	Params.Property ( "DimDr3Type", dimDr3Type );
	Params.Property ( "DimCr1", dimCr1 );
	Params.Property ( "DimCr1Type", dimCr1Type );
	Params.Property ( "DimCr2", dimCr2 );
	Params.Property ( "DimCr2Type", dimCr2Type );
	Params.Property ( "DimCr3", dimCr3 );
	Params.Property ( "DimCr3Type", dimCr3Type );
	dataDr = ServerCache.AccountData ( Params.AccountDr );
	fieldsDr = dataDr.Fields;
	levelDr = fieldsDr.Level;
	dataCr = ServerCache.AccountData ( Params.AccountCr );
	fieldsCr = dataCr.Fields;
	levelCr = fieldsCr.Level;
	Params.DataDr = dataDr;
	Params.DataCr = dataCr;
	#endregion
	#region Fields
	recordset = Params.Recordset;
	movement = recordset.Add ();
	movement.Period = Params.Date;
	movement.Company = Params.Company;
	movement.AccountDr = Params.AccountDr;
	movement.AccountCr = Params.AccountCr;
	movement.Amount = Params.Amount;
	movement.Operation = Params.Operation;
	movement.Content = ? ( content = undefined, "" + Params.Operation, content );
	Params.Property ( "Dependency", movement.Dependency );
	buffer = TypeOf ( recordset ) = Type ( "ValueTable" );
	#endregion
	#region Dr
	if ( levelDr > 0 and dimDr1 <> undefined ) then
		dimType = ? ( dimDr1Type = undefined, dataDr.Dims [ 0 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimDr1Type ] );
		value = dimType.ValueType.AdjustValue ( dimDr1 );
		if ( buffer ) then
			movement.ExtDimensionDr1 = value;
			movement.ExtDimensionTypeDr1 = dimType;
		else
			movement.ExtDimensionsDr.Insert ( dimType, value );
		endif; 
	endif; 
	if ( levelDr > 1 and dimDr2 <> undefined ) then
		dimType = ? ( dimDr2Type = undefined, dataDr.Dims [ 1 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimDr2Type ] );
		value = dimType.ValueType.AdjustValue ( dimDr2 );
		if ( buffer ) then
			movement.ExtDimensionDr2 = value;
			movement.ExtDimensionTypeDr2 = dimType;
		else
			movement.ExtDimensionsDr.Insert ( dimType, value );
		endif;
	endif; 
	if ( levelDr > 2 and dimDr3 <> undefined ) then
		dimType = ? ( dimDr3Type = undefined, dataDr.Dims [ 2 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimDr3Type ] );
		value = dimType.ValueType.AdjustValue ( dimDr3 );
		if ( buffer ) then
			movement.ExtDimensionDr3 = value;
			movement.ExtDimensionTypeDr3 = dimType;
		else
			movement.ExtDimensionsDr.Insert ( dimType, value );
		endif;
	endif; 
	if ( fieldsDr.Quantitative and quantityDr <> undefined ) then
		movement.QuantityDr = quantityDr;
	endif; 
	if ( fieldsDr.Currency ) then
		if ( currencyDr <> undefined ) then
			movement.CurrencyDr = currencyDr;
		endif;
		if ( currencyAmountDr <> undefined ) then
			movement.CurrencyAmountDr = currencyAmountDr;
		endif; 
	endif; 
	#endregion
	#region Cr
	if ( levelCr > 0 and dimCr1 <> undefined ) then
		dimType = ? ( dimCr1Type = undefined, dataCr.Dims [ 0 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimCr1Type ] );
		value = dimType.ValueType.AdjustValue ( dimCr1 );
		if ( buffer ) then
			movement.ExtDimensionCr1 = value;
			movement.ExtDimensionTypeCr1 = dimType;
		else
			movement.ExtDimensionsCr.Insert ( dimType, value );
		endif; 
	endif; 
	if ( levelCr > 1 and dimCr2 <> undefined ) then
		dimType = ? ( dimCr2Type = undefined, dataCr.Dims [ 1 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimCr2Type ] );
		value = dimType.ValueType.AdjustValue ( dimCr2 );
		if ( buffer ) then
			movement.ExtDimensionCr2 = value;
			movement.ExtDimensionTypeCr2 = dimType;
		else
			movement.ExtDimensionsCr.Insert ( dimType, value );
		endif;
	endif; 
	if ( levelCr > 2 and dimCr3 <> undefined ) then
		dimType = ? ( dimCr3Type = undefined, dataCr.Dims [ 2 ].Dim, ChartsOfCharacteristicTypes.Dimensions [ dimCr3Type ] );
		value = dimType.ValueType.AdjustValue ( dimCr3 );
		if ( buffer ) then
			movement.ExtDimensionCr3 = value;
			movement.ExtDimensionTypeCr3 = dimType;
		else
			movement.ExtDimensionsCr.Insert ( dimType, value );
		endif;
	endif; 
	if ( fieldsCr.Quantitative and quantityCr <> undefined ) then
		movement.QuantityCr = quantityCr;
	endif; 
	if ( fieldsCr.Currency ) then
		if ( currencyCr <> undefined ) then
			movement.CurrencyCr = currencyCr;
		endif;
		if ( currencyAmountCr <> undefined ) then
			movement.CurrencyAmountCr = currencyAmountCr;
		endif; 
	endif; 
	#endregion
	return movement;
	
EndFunction

Procedure Flush ( Recordset, Buffer, RemoveUseless = false ) export
	
	if ( RemoveUseless ) then
		cleanBuffer ( Buffer );
	endif;
	Buffer.GroupBy ( "
		|AccountDr,
		|AccountCr,
		|Company,
		|Content,
		|CurrencyDr,
		|CurrencyCr,
		|Dependency,
		|ExtDimensionDr1,
		|ExtDimensionDr2,
		|ExtDimensionDr3,
		|ExtDimensionTypeDr1,
		|ExtDimensionTypeDr2,
		|ExtDimensionTypeDr3,
		|ExtDimensionCr1,
		|ExtDimensionCr2,
		|ExtDimensionCr3,
		|ExtDimensionTypeCr1,
		|ExtDimensionTypeCr2,
		|ExtDimensionTypeCr3,
		|Operation,
		|Period,
		|Recorder",
		"Amount,
		|CurrencyAmountDr,
		|CurrencyAmountCr,
		|QuantityDr,
		|QuantityCr
		|" );
	if ( Recordset.Count () = 0 ) then
		Recordset.Load ( Buffer );
	else
		for each row in Buffer do
			r = Recordset.Add ();
			FillPropertyValues ( r, row );
		enddo; 
	endif; 
	
EndProcedure 

Procedure cleanBuffer ( Buffer )
	
	i = Buffer.Count ();
	while ( i > 0 ) do
		i = i - 1;
		row = Buffer [ i ];
		if ( row.AccountDr = row.AccountCr
			and row.ExtDimensionDr1 = row.ExtDimensionCr1
			and row.ExtDimensionDr2 = row.ExtDimensionCr2
			and row.ExtDimensionDr3 = row.ExtDimensionCr3
			and row.CurrencyDr = row.CurrencyCr
			and row.CurrencyAmountDr = row.CurrencyAmountCr
			and row.QuantityDr = row.QuantityCr ) then
			Buffer.Delete ( i );
		endif;
	enddo; 

EndProcedure