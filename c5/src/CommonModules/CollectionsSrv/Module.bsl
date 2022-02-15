
Procedure doTableRowExpense ( Table1, Table1Row, Table1Counter, Table2Row, Table3, ToExpense, Parameters, DecreasingColumns, RoundColumns, DecreasingColumns2, RoundColumns2, JoinedColumns )
	
	table3Row = Table3.Insert ( 0 );
	FillPropertyValues ( table3Row, Table1Row );
	rowValue = Table1Row [ Parameters.KeyColumn ];
	if ( JoinedColumns <> undefined ) then
		FillPropertyValues ( table3Row, Table2Row, JoinedColumns );
	endif; 
	keyColumnValue = CoreLibrary.KeyColumnValue ( ToExpense, rowValue );
	roundColumn = "";
	// Set key column
	table3Row [ Parameters.KeyColumn ] = keyColumnValue;
	if ( CoreLibrary.Condition1 ( rowValue, keyColumnValue ) ) then
		if ( keyColumnValue >= Table2Row [ Parameters.KeyColumn ] ) then
			for each column in DecreasingColumns2 do
				table3Row [ column.Key ] = Table2Row [ column.Key ];
				Table2Row [ column.Key ] = 0;
			enddo; 
		else
			for each column in DecreasingColumns2 do
				table3Row [ column.Key ] = Table2Row [ column.Key ] * keyColumnValue / ToExpense;
				if ( RoundColumns2.Property ( column.Key, roundColumn ) ) then
					table3Row [ column.Key ] = Round ( table3Row [ column.Key ], Table2Row [ roundColumn ] );
				endif; 
				Table2Row [ column.Key ] = Table2Row [ column.Key ] - table3Row [ column.Key ];
			enddo; 
		endif; 
		Table1Row [ Parameters.KeyColumn ] = 0;
		for each column in DecreasingColumns do
			table3Row [ column.Key ] = Table1Row [ column.Key ];
			Table1Row [ column.Key ] = 0;
		enddo; 
	else // Decrease by coefficient key column
		for each column in DecreasingColumns do
			table3Row [ column.Key ] = keyColumnValue * Table1Row [ column.Key ] / Table1Row [ Parameters.KeyColumn ];
			if ( RoundColumns.Property ( column.Key, roundColumn ) ) then
				table3Row [ column.Key ] = Round ( table3Row [ column.Key ], Table1Row [ roundColumn ] );
			endif; 
			Table1Row [ column.Key ] = Table1Row [ column.Key ] - table3Row [ column.Key ];
		enddo; 
		for each column in DecreasingColumns2 do
			table3Row [ column.Key ] = Table2Row [ column.Key ] * keyColumnValue / ? ( ToExpense = 0, 1, ToExpense );
			if ( RoundColumns2.Property ( column.Key, roundColumn ) ) then
				table3Row [ column.Key ] = Round ( table3Row [ column.Key ], Table2Row [ roundColumn ] );
			endif; 
			Table2Row [ column.Key ] = Table2Row [ column.Key ] - table3Row [ column.Key ];
		enddo; 
		Table1Row [ Parameters.KeyColumn ] = Table1Row [ Parameters.KeyColumn ] - keyColumnValue;
	endif; 
	if ( Table1Row [ Parameters.KeyColumn ] = 0 ) then
		Table1.Delete ( Table1Counter );
	endif;
	ToExpense = ToExpense - ? ( ToExpense > 0, keyColumnValue, - keyColumnValue );
	
EndProcedure
 
Function Decrease ( Table1, Table2, Parameters ) export
	
	// Create template result table
	resultTable = new ValueTable;
	for each table1Column in Table1.Columns do
		resultTable.Columns.Add ( table1Column.Name, table1Column.ValueType );
	enddo; 
	// Define decreasing and round columns
	decreasingColumns = new Structure;
	roundColumns = new Structure;
	if ( Parameters.Property ( "DecreasingColumns" ) ) then
		for each column in Conversion.StringToArray ( Parameters.DecreasingColumns ) do
			decreasingColumns.Insert ( column );
			if ( Table1.Columns.Find ( column + "Accuracy" ) <> undefined ) then
				roundColumns.Insert ( column, column + "Accuracy" );
			endif; 
		enddo; 
	endif; 
	// Define decreasing and round columns for table2
	decreasingColumns2 = new Structure;
	roundColumns2 = new Structure;
	if ( Parameters.Property ( "DecreasingColumns2" ) ) then
		for each column in Conversion.StringToArray ( Parameters.DecreasingColumns2 ) do
			if ( resultTable.Columns.Find ( column ) = undefined ) then
				resultTable.Columns.Add ( column );
			endif;
			decreasingColumns2.Insert ( column );
			if ( Table2.Columns.Find ( column + "Accuracy" ) <> undefined ) then
				roundColumns2.Insert ( column, column + "Accuracy" );
			endif; 
		enddo; 
	endif; 
	// Define filter columns
	filterColumnsDefined = Parameters.Property ( "FilterColumns" );
	if ( filterColumnsDefined ) then
		filterColumns = Conversion.StringToArray ( Parameters.FilterColumns );
	else
		filterColumns = new Array ();
	endif; 
	
	// Define optional filter columns
	optionalFilterColumns = new Structure;
	if ( Parameters.Property ( "OptionalFilterColumns" ) ) then
		for each column in Conversion.StringToArray ( Parameters.OptionalFilterColumns ) do
			optionalFilterColumns.Insert ( column );
			if ( filterColumns.Find ( column ) = undefined ) then
				filterColumns.Add ( column );
			endif; 
		enddo; 
	endif; 
	// Defined left joined attributes: Table1 Join Table2
	if ( Parameters.Property ( "AddInTable1FromTable2" ) ) then
		joinedColumns = Parameters.AddInTable1FromTable2;
		for each joinedColumn in Conversion.StringToArray ( joinedColumns ) do
			if ( resultTable.Columns.Find ( joinedColumn ) = undefined ) then
				resultTable.Columns.Add ( joinedColumn );
			endif;
		enddo; 
	else
		joinedColumns = undefined;
	endif; 
	// Key column available
	keyColumnAvailable = Parameters.Property ( "KeyColumnAvailable" );
	if ( keyColumnAvailable ) then
		if ( Table2.Columns.Find ( Parameters.KeyColumnAvailable ) = undefined ) then
			Table2.Columns.Add ( Parameters.KeyColumnAvailable, Table1.Columns [ Parameters.KeyColumn ].ValueType );
		endif;
	endif; 
	// Key column available
	otherColumnsAvailable = Parameters.Property ( "OtherColumnsAvailable" );
	if ( otherColumnsAvailable ) then
		otherColumnsAvailableMap = new Map;
		for each columnName in Conversion.StringToArray ( Parameters.OtherColumnsAvailable ) do
			if ( Table2.Columns.Find ( columnName ) = undefined ) then
				Table2.Columns.Add ( columnName, Table1.Columns [ columnName ].ValueType );
				otherColumnsAvailableMap.Insert ( columnName, Table1.Columns [ columnName ].ValueType.AdjustValue ( 0 ) );
			endif;
		enddo; 
	endif; 
	// Decrease method
	decreaseByBalances = Parameters.Property ( "DecreaseByBalances" );
	// Decrease tables
	table2Counter = Table2.Count () - 1;
	while ( table2Counter >= 0 ) do
		table2Row = Table2 [ table2Counter ];
		amountAvailableByKeyValue = 0;
		toExpense = table2Row [ Parameters.KeyColumn ];
		if ( otherColumnsAvailable ) then
			for each column in otherColumnsAvailableMap do
				otherColumnsAvailableMap [ column.Key ] = 0;
			enddo; 
		endif; 
		// For decreasing rows
		if ( decreaseByBalances = true ) then
			table1RowsIndex = new Array;
		endif; 
		table1Counter = Table1.Count () - 1;
		while ( table1Counter >= 0 ) do
			table1Row = Table1 [ table1Counter ];
			decreaseRow = not filterColumnsDefined;
			for each table1Column in filterColumns do
				if ( not optionalFilterColumns.Property ( table1Column ) or ValueIsFilled ( table2Row [ table1Column ] ) ) then
					if ( table2Row [ table1Column ] <> table1Row [ table1Column ] ) and
						( ValueIsFilled ( table2Row [ table1Column ] ) or ValueIsFilled ( table1Row [ table1Column ] ) ) then
						decreaseRow = false;
						break;
					else
						decreaseRow = true;
					endif;
				endif; 
			enddo; 
			// Rows matched, decrease resources
			if ( decreaseRow ) then
				amountAvailableByKeyValue = amountAvailableByKeyValue + table1Row [ Parameters.KeyColumn ];
				if ( otherColumnsAvailable ) then
					for each column in otherColumnsAvailableMap do
						otherColumnsAvailableMap [ column.Key ] = otherColumnsAvailableMap [ column.Key ] + table1Row [ column.Key ];
					enddo; 
				endif; 
				if ( decreaseByBalances ) then // Collect balance, save rows for decreasing (method for Inventory-documents)
					table1RowsIndex.Add ( table1Counter );
				else // method for Sales-documents
					doTableRowExpense ( Table1, table1Row, table1Counter, table2Row, resultTable, toExpense, Parameters, decreasingColumns, roundColumns, decreasingColumns2, roundColumns2, joinedColumns );
					if ( toExpense = 0 ) then
						break;
					endif; 
				endif; 
			endif; 
			table1Counter = table1Counter - 1;
		enddo; 
		// Inventory-documents
		if ( decreaseByBalances ) then
			toExpense = amountAvailableByKeyValue - table2Row [ Parameters.KeyColumn ];
			toExpenseInit = toExpense;
			if ( toExpense <> 0 ) then
				for each table1Index in table1RowsIndex do
					table1Row = Table1 [ table1Index ];
					doTableRowExpense ( Table1, table1Row, table1Index, table2Row, resultTable, toExpense, Parameters, decreasingColumns, roundColumns, decreasingColumns2, roundColumns2, joinedColumns );
					if ( toExpense = 0 ) then
						break;
					endif; 
				enddo;
			endif;
		endif;
		// Delete empty rows or put information for error
		if ( not decreaseByBalances and toExpense = 0 and amountAvailableByKeyValue <> 0 ) or
			( decreaseByBalances and toExpense = 0 and toExpenseInit > 0 and amountAvailableByKeyValue <> 0 ) then
			Table2.Delete ( table2Counter );
		else
			if ( keyColumnAvailable ) then // Put for errors
				table2Row [ Parameters.KeyColumnAvailable ] = amountAvailableByKeyValue;
			endif;
			if ( otherColumnsAvailable ) then
				for each column in otherColumnsAvailableMap do
					table2Row [ column.Key ] = column.Value;
				enddo; 
			endif; 
		endif;
		table2Counter = table2Counter - 1;
	enddo; 
	return resultTable;
	
EndFunction

Function Combine ( Table1, Table2, Parameters, UnresolvedRoundTable = undefined ) export
	
	// Define assign columns
	assignColumsTable1 = ? ( Parameters.Property ( "AssignСоlumnsTаble1" ), Parameters.AssignСоlumnsTаble1, undefined );
	assignColumsTable2 = ? ( Parameters.Property ( "AssignColumnsTable2" ), Parameters.AssignColumnsTable2, undefined );
	assignColumsTable2Soft = ? ( Parameters.Property ( "AssignColumnsTable2Soft" ), Parameters.AssignColumnsTable2Soft, false );
	assignColumsTable2Array = new Array;
	keyColumn = Table1.Columns.Find ( Parameters.KeyColumn );
	if ( keyColumn = undefined ) then
		keyColumnType = new TypeDescription ( "Number" );
		Table1.Columns.Add ( Parameters.KeyColumn, keyColumnType );
		Table1.FillValues ( 1, Parameters.KeyColumn );
	else
		keyColumnType = keyColumn.ValueType;
	endif; 
	// Create template result table
	resultTable = new ValueTable;
	if ( assignColumsTable1 = undefined ) then
		for each tableColumn in Table1.Columns do
			if ( resultTable.Columns.Find ( tableColumn.Name ) = undefined ) then
				resultTable.Columns.Add ( tableColumn.Name, tableColumn.ValueType );
			endif; 
		enddo;
	else
		for each tableColumn in Conversion.StringToArray ( assignColumsTable1 ) do
			if ( resultTable.Columns.Find ( tableColumn ) = undefined ) then
				resultTable.Columns.Add ( tableColumn, Table1.Columns [ tableColumn ].ValueType );
			endif; 
		enddo;
	endif; 
	if ( assignColumsTable2 = undefined ) then
		for each tableColumn in Table2.Columns do
			if ( resultTable.Columns.Find ( tableColumn.Name ) = undefined ) then
				resultTable.Columns.Add ( tableColumn.Name, tableColumn.ValueType );
			endif; 
		enddo;
	else
		for each tableColumn in Conversion.StringToArray ( assignColumsTable2 ) do
			if ( resultTable.Columns.Find ( tableColumn ) = undefined ) then
				resultTable.Columns.Add ( tableColumn, Table2.Columns [ tableColumn ].ValueType );
			endif; 
			assignColumsTable2Array.Add ( tableColumn );
		enddo;
	endif;
	if ( resultTable.Columns.Find ( Parameters.KeyColumn ) = undefined ) then
		resultTable.Columns.Add ( Parameters.KeyColumn, keyColumnType );
	endif; 
	// Define distributed columns Table1
	distribColumnsTable1 = new Structure;
	correctValues = new Structure;
	roundColumns = new Structure;
	maxValuesResultTable = new Structure;
	if ( Parameters.Property ( "DistribColumnsTable1" ) ) then
		for each column in Conversion.StringToArray ( Parameters.DistribColumnsTable1 ) do
			distribColumnsTable1.	Insert ( column );
			correctValues.			Insert ( column, 0 ); // Numeric
			maxValuesResultTable.Insert ( column, new Structure ( "Value, LineIndex", undefined ) );
			if ( resultTable.Columns.Find ( column ) = undefined ) then
				resultTable.Columns.Add ( column, Table1.Columns [ column ].ValueType );
			endif; 
			if ( Table1.Columns.Find ( column + "Accuracy" ) <> undefined ) then
				roundColumns.Insert ( column, column + "Accuracy" );
			else
				roundColumns.Insert ( column, undefined );
			endif; 
		enddo;
	endif; 
	// Define distributed columns Table2
	distribColumnsTable2 = new Structure;
	table2DistrColumnsStructure = new Structure;
	correctValuesTable2 = new Structure;
	distributeTable2Columns = Parameters.Property ( "DistribColumnsTable2" );
	if ( distributeTable2Columns ) then
		for each column in Conversion.StringToArray ( Parameters.DistribColumnsTable2 ) do
			distribColumnsTable2.			Insert ( column );
			table2DistrColumnsStructure.	Insert ( column );
			correctValuesTable2.			Insert ( column, 0 );
			if ( resultTable.Columns.Find ( column ) = undefined ) then
				resultTable.Columns.Add ( column, Table2.Columns [ column ].ValueType );
			endif; 
		enddo; 
	endif;
	// Correct distributed columns for Table1
	if ( not distribColumnsTable1.Property ( Parameters.KeyColumn ) ) and ( not distribColumnsTable2.Property ( Parameters.KeyColumn ) ) then
		distribColumnsTable1.	Insert ( Parameters.KeyColumn );
		correctValues.			Insert ( Parameters.KeyColumn, 0 ); // Numeric
		maxValuesResultTable.Insert ( Parameters.KeyColumn, new Structure ( "Value, LineIndex", undefined ) );
		if ( Table1.Columns.Find ( Parameters.KeyColumn + "Accuracy" ) <> undefined ) then
			roundColumns.Insert ( Parameters.KeyColumn, Parameters.KeyColumn + "Accuracy" );
		else
			roundColumns.Insert ( Parameters.KeyColumn, undefined );
		endif; 
	endif; 
	// Define filter columns
	filterColumns = Conversion.StringToArray ( Parameters.FilterColumns );
	CollectionsSrv.AdjustTable ( Table1, Table2, Parameters.FilterColumns );
	// Define UnresolvedRoundTable
	UnresolvedRoundTable = resultTable.CopyColumns ();
	for each item in roundColumns do
		if ( item.Value = undefined ) or ( resultTable.Columns.Find ( item.Value ) <> undefined ) then
			continue;
		endif; 
		UnresolvedRoundTable.Columns.Add ( item.Value );
	enddo; 
	
	// Distribute Table1 by Table2
	// *************************************
	if ( Parameters.Property ( "DistributeTables" ) ) then
		// Copy parameters for recourse combine tables
		copyParameters = copyObject ( Parameters );
		//@skip-warning
		copyParameters.Delete ( "DistributeTables" );
		fieldsEquals = new Array;
		filterColumnsArray= copyObject ( filterColumns );
		while ( filterColumnsArray.Count () > 0 ) and ( Table1.Count () > 0 ) do
			searchStructure = new Structure;
			searchStructureTable2 = new Structure;
			table2Counter = Table2.Count () - 1;
			copyTable2 = Table2.Copy ();
			while ( table2Counter >= 0 ) do
				table2Row = copyTable2 [ table2Counter ];
				for each field in filterColumnsArray do
					searchStructureTable2.Insert ( field, table2Row [ field ] );
				enddo; 
				for each field in filterColumnsArray do
					searchStructure.Insert ( field, table2Row [ field ] );
				enddo;
				if ( fieldsEquals.Count () > 0 ) then
					for each field in fieldsEquals do
						if ( Table2.Columns [ field ].ValueType.Types ().Count () > 1 ) then
							searchStructure.Insert ( field, undefined );
						else
							searchStructure.Insert ( field, getEmptyRefByValue ( table2Row [ field ] ) );
						endif; 
					enddo; 
				endif; 
				table1ByRows = Slice ( Table1, searchStructure );
				if ( table1ByRows.Count () ) then
					table2ByRows = Slice ( copyTable2, searchStructureTable2 );
					// Set FilterColumns for distribute table1ByRows and table2ByRows
					copyParameters.FilterColumns = StrConcat ( filterColumnsArray, "," );
					// Combine tables
					Join ( resultTable, CollectionsSrv.Combine ( table1ByRows, table2ByRows, copyParameters ) );
					table2Counter = copyTable2.Count ();
				endif; 
				table2Counter = table2Counter - 1;
			enddo;
			fieldsEquals.Add ( filterColumnsArray [ filterColumnsArray.UBound () ] );
			filterColumnsArray.Delete ( filterColumnsArray.UBound () );
		enddo;
	// Combine tables
	// *************************************
	else
		table1Counter = Table1.Count () - 1;
		while ( table1Counter >= 0 ) do
			// Find rows by Table2
			searchStructure = new Structure;
			for each item in filterColumns do
				searchStructure.Insert ( item, Table1 [ table1Counter ] [ item ] );
			enddo;
			table1RowsArray = Table1.FindRows ( searchStructure );
			table2RowsArray = Table2.FindRows ( searchStructure );
			if ( table2RowsArray.Count () = 0 ) then
				table1Counter = table1Counter - 1;
				continue;
			endif;
			// Collect totals by Table2 for distribute numeric columns Table2
			if ( distributeTable2Columns ) then
				for each item in distribColumnsTable2 do
					table2DistrColumnsStructure [ item.Key ] = 0;
					for each table2Row in table2RowsArray do
						table2DistrColumnsStructure [ item.Key ] = table2DistrColumnsStructure [ item.Key ] + table2Row [ item.Key ];
					enddo; 
				enddo; 
			endif; 
			resultTableIndexBeforeIncrement = resultTable.Count ();
			for each table1Row in table1RowsArray do
				totalAmount = 0;
				for each table2Row in table2RowsArray do
					totalAmount = totalAmount + table2Row [ Parameters.KeyColumn ];
				enddo; 
				totalAmount = ? ( totalAmount = 0, 1, totalAmount );
				// Distribute distribColumnsTable1
				comingIndex = resultTable.Count () - 1;
				for each table2Row in table2RowsArray do
					resultTableRow = resultTable.Add ();
					resultTableRowIndex = resultTable.Count () - 1;
					FillPropertyValues ( resultTableRow, table1Row );
					FillPropertyValues ( resultTableRow, table2Row );
					if ( assignColumsTable1 <> undefined ) then
						FillPropertyValues ( resultTableRow, table1Row, assignColumsTable1 );
					endif; 
					if ( assignColumsTable2 <> undefined ) then
						if ( assignColumsTable2Soft ) then // test fields by ValueIsFilled ()
							for each assignColumnTable2 in assignColumsTable2Array do
								if ( ValueIsFilled ( table2Row [ assignColumnTable2 ] ) ) then
									resultTableRow [ assignColumnTable2 ] = table2Row [ assignColumnTable2 ];
								endif; 
							enddo; 
						else
							FillPropertyValues ( resultTableRow, table2Row, assignColumsTable2 );
						endif; 
					endif; 
					for each distrColumn in distribColumnsTable1 do
						resultTableRow [ distrColumn.Key ] = table1Row [ distrColumn.Key ] * table2Row [ Parameters.KeyColumn ] / totalAmount;
						if ( roundColumns [ distrColumn.Key ] <> undefined ) then
							resultTableRow [ distrColumn.Key ] = Round ( resultTableRow [ distrColumn.Key ], table1Row [ roundColumns [ distrColumn.Key ] ] );
						endif; 
						if ( maxValuesResultTable [ distrColumn.Key ].Value = undefined
							or maxValuesResultTable [ distrColumn.Key ].Value < resultTableRow [ distrColumn.Key ] ) then
							maxValuesResultTable [ distrColumn.Key ].Value = resultTableRow [ distrColumn.Key ];
							maxValuesResultTable [ distrColumn.Key ].LineIndex = resultTableRowIndex;
						endif; 
						correctValues [ distrColumn.Key ] = correctValues [ distrColumn.Key ] + resultTableRow [ distrColumn.Key ];
					enddo; 
				enddo; 
				// Correct distribution
				if ( table2RowsArray.Count () > 0 ) then
					for each distrColumn in distribColumnsTable1 do
						biggerRow = resultTable [ maxValuesResultTable [ distrColumn.Key ].LineIndex ];
						biggerRow [ distrColumn.Key ] = biggerRow [ distrColumn.Key ] - ( correctValues [ distrColumn.Key ] - table1Row [ distrColumn.Key ] );
						saveValue = biggerRow [ distrColumn.Key ];
						if ( roundColumns [ distrColumn.Key ] <> undefined ) then
							biggerRow [ distrColumn.Key ] = Round ( biggerRow [ distrColumn.Key ], table1Row [ roundColumns [ distrColumn.Key ] ] );
							if ( biggerRow [ distrColumn.Key ] <> saveValue ) then // Unresolved round
								unresolvedRow = UnresolvedRoundTable.Add ();
								FillPropertyValues ( unresolvedRow, resultTableRow );
								unresolvedRow [ roundColumns [ distrColumn.Key ] ] = saveValue - biggerRow [ distrColumn.Key ];
							endif; 
						endif; 
						correctValues [ distrColumn.Key ] = 0;
						maxValuesResultTable [ distrColumn.Key ].Value = undefined;
					enddo; 
				endif; 
				// Remove distributed row
				Table1.Delete ( table1Row );
				// Clean undistributed rows (because of too small values for instance
				i = resultTable.Count () - 1;
				while ( i > comingIndex ) do
					empty = true;
					for each distrColumn in distribColumnsTable1 do
						if ( resultTable [ i ] [ distrColumn.Key ] <> 0 ) then
							empty = false;
							break;
						endif;
					enddo;
					if ( empty ) then
						resultTable.Delete ( i );
					endif;
					i = i - 1;
				enddo;
			enddo;
			// Distribute Table2 columns
			lastRowIndexResultTable = ( resultTable.Count () - 1 );
			if ( CoreLibrary.Condition2 ( lastRowIndexResultTable, distributeTable2Columns, resultTableIndexBeforeIncrement ) ) then
				totalAmount = 0;
				for i = resultTableIndexBeforeIncrement to lastRowIndexResultTable do
					totalAmount = totalAmount + resultTable [ i ] [ Parameters.KeyColumn ];
				enddo; 
				totalAmount = ? ( totalAmount = 0, 1, totalAmount );
				// Distribute distribColumnsTable2
				for i = resultTableIndexBeforeIncrement to lastRowIndexResultTable do
					resultTableRow = resultTable [ i ];
					for each distrColumn in distribColumnsTable2 do
						resultTableRow [ distrColumn.Key ] = table2DistrColumnsStructure [ distrColumn.Key ] * resultTableRow [ Parameters.KeyColumn ] / totalAmount;
						correctValuesTable2 [ distrColumn.Key ] = correctValuesTable2 [ distrColumn.Key ] + resultTableRow [ distrColumn.Key ];
					enddo; 
				enddo; 
				// Correct distribution
				for each distrColumn in distribColumnsTable2 do
					resultTableRow [ distrColumn.Key ] = resultTableRow [ distrColumn.Key ] - ( correctValuesTable2 [ distrColumn.Key ] - table2DistrColumnsStructure [ distrColumn.Key ] );
					correctValuesTable2 [ distrColumn.Key ] = 0;
				enddo; 
			endif; 
			// Refresh counter
			table1Counter = Table1.Count () - 1;
		enddo;
	endif; 
	// Attach undistributed table
	if ( Parameters.Property ( "IncludeUndistributedTable" ) ) then
		for each table1Row in Table1 do
			resultTableRow = resultTable.Add ();
			FillPropertyValues ( resultTableRow, table1Row );
		enddo; 
	endif; 
	return resultTable;
	
EndFunction

Function getEmptyRefByValue ( Value )

	if ( Value = Undefined ) then
		return Undefined;
	endif; 
	if ( TypeOf ( Value ) = Type ( "Number" ) ) then
		return 0;
	elsif ( TypeOf ( Value ) = Type ( "Date" ) ) then
		return Date ( '00010101' );
	elsif ( isRef ( Value, "Catalog" ) ) then
		return Catalogs [ Value.Metadata ().Name ].EmptyRef ();
	elsif ( isRef ( Value, "Document" ) ) then
		return Documents [ Value.Metadata ().Name ].EmptyRef ();
	elsif ( isRef ( Value, "Enum" ) ) then
		return Enums [ Value.Metadata ().Name ].EmptyRef ();
	elsif ( isRef ( Value, "ChartOfCharacteristicTypes" ) ) then
		return ChartsOfCharacteristicTypes [ Value.Metadata ().Name ].EmptyRef ();
	elsif ( isRef ( Value, "ChartOfAccounts" ) ) then
		return ChartsOfAccounts [ Value.Metadata ().Name ].EmptyRef ();
	elsif ( isRef ( Value, "ChartOfCalculationTypes" ) ) then
		return ChartsOfCalculationTypes [ Value.Metadata ().Name ].EmptyRef ();
	endif; 

EndFunction

Function isRef ( Ref, RefType, RefName = "" )

	if ( Ref = undefined ) then
		return false;
	endif; 
	if ( RefType = "Catalog" ) then
		if ( RefName = "" ) then
			return Catalogs.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( Catalogs [ RefName ].EmptyRef () );
		endif;
	elsif ( RefType = "Document" ) then
		if ( RefName = "" ) then
			return Documents.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( Documents [ RefName ].EmptyRef () );
		endif;
	elsif ( RefType = "Enum" ) then
		if ( RefName = "" ) then
			return Enums.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( Enums [ RefName ].EmptyRef () );
		endif;
	elsif ( RefType = "ChartOfCharacteristicTypes" ) then
		if ( RefName = "" ) then
			return ChartsOfCharacteristicTypes.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( ChartsOfCharacteristicTypes [ RefName ].EmptyRef () );
		endif;
	elsif ( RefType = "ChartOfAccounts" ) then
		if ( RefName = "" ) then
			return ChartsOfAccounts.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( ChartsOfAccounts [ RefName ].EmptyRef () );
		endif;
	elsif ( RefType = "ChartOfCalculationTypes" ) then
		if ( RefName = "" ) then
			return ChartsOfCalculationTypes.AllRefsType ().ContainsType ( TypeOf ( Ref ) );
		else
			return TypeOf ( Ref ) = TypeOf ( ChartsOfCalculationTypes [ RefName ].EmptyRef () );
		endif;
	endif; 

EndFunction

Function copyObject ( Object )

	if ( TypeOf ( Object ) = Type ( "Array" ) ) then
		valList = new ValueList;
		valList.LoadValues ( Object );
		newObject = valList.UnloadValues ();
	elsif ( TypeOf ( Object ) = Type ( "Structure" ) ) then
		newObject = new Structure;
		for each item in Object do
			newObject.Insert ( item.Key, item.Value );
		enddo; 
	elsif ( TypeOf ( Object ) = Type ( "Map" ) ) then
		newObject = new Map;
		for each item in Object do
			newObject.Insert ( item.Key, item.Value );
		enddo; 
	elsif ( TypeOf ( Object ) = Type ( "ValueList" ) ) then
		newObject = Object.Copy ();
	else
		s = ValueToStringInternal ( Object );
		newObject = ValueFromStringInternal ( s );
	endif;
	return newObject;
	
EndFunction

Procedure Group ( Table, GrouppingColumns, AmountmationColumns, AveragingColumns = undefined ) export
	
	if ( Table.Count () = 0 ) then
		return;
	endif; 
	if ( AveragingColumns = undefined ) then
		averagingColumns = AmountmationColumns;
	else
		averagingColumns = AveragingColumns;
	endif; 
	// Add unique column for calcule average
	uniqueColumn = "__GroupCounter__";
	Table.Columns.Add ( uniqueColumn );
	Table.FillValues ( 1, uniqueColumn );
	Table.GroupBy ( GrouppingColumns, AmountmationColumns + ", " + uniqueColumn );
	averagingColumnsArray = Conversion.StringToArray ( averagingColumns );
	for each tableRow in Table do
		for each averagingColumn in averagingColumnsArray do
			tableRow [ averagingColumn ] = tableRow [ averagingColumn ] / tableRow [ uniqueColumn ];
		enddo;
	enddo; 
	Table.Columns.Delete ( Table.Columns [ uniqueColumn ] );
	
EndProcedure

Procedure Adjust ( Table, Column, Type ) export
	
	array = Table.UnloadColumn ( Column );
	Table.Columns.Add ( "_____TempForAdjust", Type );
	Table.LoadColumn ( array, "_____TempForAdjust" );
	Table.Columns.Delete ( Column );
	Table.Columns._____TempForAdjust.Name = Column;
	
EndProcedure

Procedure AdjustTable ( Table1, Table2, AdjustedColumns ) export
	
	adjustStruct = Conversion.StringToStructure ( AdjustedColumns );
	// Define filter columns
	parseTableColumns = new Array;
	for each column in adjustStruct do
		table1Column = column.Key;
		table2Column = ? ( column.Value = "", column.Key, column.Value );
		// Create new ValueType without null
		typesArray = new Array;
		table2ColumnTypes = Table2.Columns [ table2Column ].ValueType.Types ();
		for each typeItem in table2ColumnTypes do
			if ( typeItem <> TypeOf ( null ) ) then
				typesArray.Add ( typeItem );
			endif; 
		enddo; 
		// Adjust column Table1
		Table1.Columns.Add ( "___TemporaryColumn", new TypeDescription ( typesArray ) );
		Table1.LoadColumn ( Table1.UnloadColumn ( table1Column ), "___TemporaryColumn" );
		Table1.Columns.Delete ( table1Column );
		Table1.Columns.___TemporaryColumn.Name = table1Column;
		// Adjust column Table2
		if ( typesArray.Count () <> table2ColumnTypes.Count () ) then
			Table2.Columns.Add ( "___TemporaryColumn", new TypeDescription ( typesArray ) );
			Table2.LoadColumn ( Table2.UnloadColumn ( table2Column ), "___TemporaryColumn" );
			Table2.Columns.Delete ( table2Column );
			Table2.Columns.___TemporaryColumn.Name = table2Column;
		endif; 
		if ( Table2.Columns [ table2Column ].ValueType.Types ().Count () > 1 ) then
			parseTableColumns.Add ( new Structure ( "Column1, Column2", table1Column, table2Column ) );
		endif; 
	enddo; 
	if ( parseTableColumns.Count () > 0 ) then
		for each table1Row in Table1 do
			for each table1Column in parseTableColumns do
				if ( not ValueIsFilled ( table1Row [ table1Column.Column1 ] ) ) then
					table1Row [ table1Column.Column1 ] = undefined;
				endif; 
			enddo; 
		enddo; 
		for each table2Row in Table2 do
			for each table2Column in parseTableColumns do
				if ( not ValueIsFilled ( table2Row [ table2Column.Column2 ] ) ) then
					table2Row [ table2Column.Column2 ] = undefined;
				endif; 
			enddo; 
		enddo; 
	endif; 
	
EndProcedure

Function Slice ( Table, Filter, TableRowsRemove = true ) export
	
	if ( not TableRowsRemove ) then
		return Table.Copy ( Filter );
	endif;
	result = getEmptyTable ( Table );
	rows = Table.FindRows ( Filter );
	for each row in rows do
		newRow = result.Add ();
		FillPropertyValues ( newRow, row );
		Table.Delete ( row );
	enddo; 
	return result;
	
EndFunction

Function getEmptyTable ( Table )
	
	if ( TypeOf ( Table ) = Type ( "ValueTable" )  ) then
		return Table.CopyColumns ();
	else
		result = new ValueTable ();
		columns = Metadata.FindByType ( TypeOf ( Table ) ).Attributes;
		for each column in columns do
			result.Columns.Add ( column.Name, column.Type );
		enddo; 
		return result;
	endif; 
	
EndFunction

Procedure Join ( Table1, Table2 ) export
	
	if ( TypeOf ( Table1 ) = Type ( "ValueTable" ) ) then
		if ( Table1.Columns.Count () = 0 ) then
			Table1 = Table2.CopyColumns ();
		endif;
	endif; 
	for each row in Table2 do
		newRow = Table1.Add ();
		FillPropertyValues ( newRow, row );
	enddo; 
	
EndProcedure

Function GetDuplicates ( Table, Columns = undefined ) export
	
	if ( Table.Count () < 2 ) then
		return undefined;
	endif; 
	if ( TypeOf ( Table ) = Type ( "ValueTable" ) ) then
		columnsCollection = ? ( Columns = undefined, Table.Columns, Columns );
		groupTable = Table.Copy ();
	else
		columnsCollection = ? ( Columns = undefined, Metadata.FindByType ( TypeOf ( Table ) ).Attributes, Columns );
		groupTable = Table.Unload ();
	endif;
	if ( Columns = undefined ) then
		s = "";
		for each column in columnsCollection do
			s = s + column.Name + ", ";
		enddo; 
		columnsCollection = Left ( s, StrLen ( s ) - 2 );
	endif; 
	if ( IsBlankString ( columnsCollection ) ) then
		return undefined;
	endif; 
	groupTable.Columns.Add ( "___ServiceColumn___", new TypeDescription ( "Number" ) );
	groupTable.FillValues ( 1, "___ServiceColumn___" );
	groupTable.GroupBy ( columnsCollection, "___ServiceColumn___" );
	groupTableCount = groupTable.Count ();
	if ( groupTableCount = Table.Count () ) then
		return undefined;
	else
		counter = groupTableCount - 1;
		while ( counter >= 0 ) do
			if ( groupTable [ counter ].___ServiceColumn___ = 1 ) then
				groupTable.Delete ( counter );
			endif; 
			counter = counter - 1;
		enddo; 
		if ( groupTable.Count () = 0 ) then
			return undefined;
		endif; 
		return groupTable;
	endif; 
	
EndFunction

Function Serialize ( Table ) export
	
	result = new Structure ();
	colums = new Array ();
	for each column in Table.Columns do
		result.Insert ( column.Name, new Array () );
		colums.Add ( column.Name );
	enddo; 
	for each row in Table do
		for each column in colums do
			result [ column ].Add ( row [ column ] );
		enddo; 
	enddo; 
	result.Insert ( "_Ubound", Table.Count () - 1 );
	result.Insert ( "_Columns", colums );
	return result;
	
EndFunction

Function SerializeTree ( Tree ) export
	
	rowsArray = new Array ();
	columns = "Rows,";
	for each column in Tree.Columns do
		columns = columns + column.Name + ",";
	enddo; 
	serializeRows ( Tree.Rows, columns, rowsArray );
	return rowsArray;
	
EndFunction

Procedure serializeRows ( Rows, Columns, RowsArray )
	
	i = 0;
	for each row in Rows do
		RowsArray.Add ( new Structure ( Columns ) );
		storedRow = RowsArray [ i ];
		FillPropertyValues ( storedRow, row );
		storedRow.Rows = new Array ();
		if ( row.Rows.Count () > 0 ) then
			serializeRows ( row.Rows, Columns, storedRow.Rows );
		endif; 
		i = i + 1;
	enddo; 
	
EndProcedure
