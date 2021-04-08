
Procedure Distribute ( DistributedAmount, Table, KeyColumn, ResultColumn, Overwrite = true ) export

	#if ( Server ) then
		if ( TypeOf ( Table ) = Type ( "ValueTable" ) ) then
			if ( Table.Columns.Find ( ResultColumn ) = undefined ) then
				Table.Columns.Add ( ResultColumn, new TypeDescription ( "Number" ) );
			endif; 
		endif; 
	#endif
	if ( Table.Count () = 0 ) then
		return;
	endif; 
	totalsByKeyColumn = Table.Total ( KeyColumn );
	totalsByKeyColumn = ? ( totalsByKeyColumn = 0, 1, totalsByKeyColumn );
	for each tableRow in Table do
		if ( Overwrite ) then
			tableRow [ ResultColumn ] = DistributedAmount * tableRow [ KeyColumn ] / totalsByKeyColumn;
		else
			tableRow [ ResultColumn ] = tableRow [ ResultColumn ] + ( DistributedAmount * tableRow [ KeyColumn ] / totalsByKeyColumn );
		endif; 
	enddo; 
	tableRow = Table [ Table.Count () - 1 ];
	tableRow [ ResultColumn ] = tableRow [ ResultColumn ] + ( DistributedAmount - Table.Total ( ResultColumn ) );
	
EndProcedure

Procedure Slice ( SlicedAmount, Table, KeyColumn, ResultColumn, Filter = undefined ) export
	
	amount = SlicedAmount;
	existFilter = Filter <> undefined;
	for each row in Table do
		if ( existFilter ) then
			skipRow = false;
			for each filterItem in Filter do
				if ( row [ filterItem.Key ] <> filterItem.Value ) then
					skipRow = true;
					break;
				endif; 
			enddo; 
			if ( skipRow ) then
				row [ ResultColumn ] = 0;
				continue;
			endif; 
		endif; 
		row [ ResultColumn ] = Min ( amount, row [ KeyColumn ] );
		amount = amount - row [ ResultColumn ];
	enddo; 
	
EndProcedure

&AtClient
Procedure FillDataCollection ( Table, Column, Value ) export
	
	for each row in Table do
		row [ Column ] = Value;
	enddo; 
	
EndProcedure

Procedure Group ( A ) export

	groupped = new Array ();
	for each item in A do
		if ( groupped.Find ( item ) = undefined ) then
			groupped.Add ( item );
		endif; 
	enddo; 
	A = groupped;
	
EndProcedure
 
Procedure Sort ( A ) export
	
	list = new ValueList ();
	list.LoadValues ( A );
	list.SortByValue ();
	A = list.UnloadValues ();
	
EndProcedure 

Function DeserializeTable ( SerializedTable ) export
	
	result = new Array ();
	a = SerializedTable._Columns;
	columns = StrConcat ( a, "," );
	row = new Structure ( columns );
	for i = 0 to SerializedTable._Ubound do
		resultRow = new Structure ( columns );
		deserializeTableRow ( row, SerializedTable, i );
		FillPropertyValues ( resultRow, row );
		result.Add ( resultRow );
	enddo; 
	return result;
	
EndFunction

Procedure deserializeTableRow ( Row, SerializedTable, Index ) export
	
	for each column in SerializedTable._Columns do
		Row [ column ] = SerializedTable [ column ] [ Index ];
	enddo; 
	
EndProcedure 

Procedure DeserializeFormTable ( FormData, SerializedTable, ClearFormData = true ) export
	
	if ( ClearFormData ) then
		FormData.Clear ();
	endif; 
	a = SerializedTable._Columns; // Bug workaround. Webclient 8.3.6.x gives error when StrConcat (...) is performed through "dot"
	row = new Structure ( StrConcat ( a, "," ) );
	for i = 0 to SerializedTable._Ubound do
		deserializeTableRow ( row, SerializedTable, i );
		dataRow = FormData.Add ();
		FillPropertyValues ( dataRow, row );
	enddo; 
	
EndProcedure

Procedure DeserializeTree ( FormData, SerializedTree, ClearFormData = true ) export
	
	if ( ClearFormData ) then
		dataItems = FormData.GetItems ();
		dataItems.Clear ();
	endif; 
	deserializeRows ( dataItems, SerializedTree );
	
EndProcedure

Procedure deserializeRows ( DataItems, SerializedRows )
	
	for each row in SerializedRows do
		dataRow = DataItems.Add ();
		FillPropertyValues ( dataRow, row );
		if ( row.Rows.Count () > 0 ) then
			deserializeRows ( dataRow.GetItems (), row.Rows );
		endif; 
	enddo; 
	
EndProcedure 

Function CopyStructure ( Struct ) export

	newStructure = new Structure ();
	for each item in Struct do
		newStructure.Insert ( item.Key, item.Value );
	enddo; 
	return newStructure;
		
EndFunction 

Function GetFields ( Object, Fields ) export
	
	fields = new Structure ( Fields );
	FillPropertyValues ( fields, Object );
	return fields;
	
EndFunction  

Function GetDoubles ( Table, Columns ) export
	
	doubles = new Array ();
	skipRows = new Map ();
	searchStruct = new Structure ( Columns );
	for each row in Table do
		if ( skipRows [ row ] = true ) then
			continue;
		endif; 
		FillPropertyValues ( searchStruct, row );
		foundRows = Table.FindRows ( searchStruct );
		if ( foundRows.Count () > 1 ) then
			doubles.Add ( foundRows [ 1 ] );
			for each foundRow in foundRows do
				skipRows [ foundRow ] = true;
			enddo; 
		endif; 
	enddo; 
	return doubles;
	
EndFunction 
