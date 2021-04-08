#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

#if ( Server ) then

Function Set ( Table, Generation ) export

	SetPrivilegedMode ( true );
	emptyRows = Table.FindRows ( new Structure ( "RowKey", Catalogs.RowKeys.EmptyRef () ) );
	emptyRowsCount = emptyRows.Count ();
	if ( emptyRowsCount > 0 ) then
		max = ( Generation - 1 ) * 100000 + 1;
		if ( emptyRowsCount <> Table.Count () ) then
			for each row in Table do
				if ( not row.RowKey.IsEmpty () ) and ( max < row.RowKey.Code ) then
					max = row.RowKey.Code;
				endif; 
			enddo; 
			max = max + 1;
		endif; 
		for each row in emptyRows do
			rowKey = Catalogs.RowKeys.FindByCode ( max );
			if ( rowKey.IsEmpty () ) then
				rowKeyObject = Catalogs.RowKeys.CreateItem ();
				rowKeyObject.Code = max;
				try
					rowKeyObject.Write ();
				except
					Output.StoreDataErrorTryAgain ();
					SetPrivilegedMode ( false );
					return false;
				endtry;
				rowKey = rowKeyObject.Ref;
			endif; 
			row.RowKey = rowKey;
			max = max + 1;
		enddo; 
	endif; 
	SetPrivilegedMode ( false );
	return true;
	
EndFunction

#endif

#endif