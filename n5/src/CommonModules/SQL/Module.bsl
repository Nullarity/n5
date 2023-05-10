Function Create ( Query ) export
	
	env = new Structure ();
	env.Insert ( "Q", new Query () );
	env.Insert ( "Selection", new Array () );
	env.Selection.Add ( Query );
	return env;
	
EndFunction

Procedure Init ( Env ) export
	
	if ( Env = undefined ) then
		Env = new Structure ();
	endif; 
	Env.Insert ( "Q", new Query () );
	Env.Insert ( "Selection", new Array () );
	
EndProcedure

Procedure Prepare ( Env ) export
	
	q = Env.Q;
	q.Text = StrConcat ( Env.Selection, ";" );
	SQL.DefineTempManager ( q );
	Env.Selection = new Array ();

EndProcedure 

Procedure DefineTempManager ( Q ) export
	
	if ( Find ( Q.Text, "into " ) > 0
		or Find ( Q.Text, "INTO " ) > 0 ) then
		if ( Q.TempTablesManager = undefined ) then
			Q.TempTablesManager = new TempTablesManager ();
		endif; 
	endif; 
	
EndProcedure 

Procedure Unload ( Env, Data = undefined ) export

	q = Env.Q;
	tables = CoreLibrary.QueryTables ( q.Text );
	result = ? ( Data = undefined, q.ExecuteBatch (), Data );
	if ( tables <> undefined ) then
		extractData ( tables, Env, result );
	endif;
	
EndProcedure

Procedure extractData ( Tables, Env, Data )
	
	indexExists = false;
	for each table in Tables do
		type = table.Type;
		name = table.Name;
		index = table.Index;
		if ( type = 1 ) then
			Env.Insert ( name, Data [ index ].Unload () );
		elsif ( type = 2 ) then
			Env.Insert ( "i" + name, index );
			indexExists = true;
		else
			rows = Data [ index ].Unload ();
			if ( rows.Count () = 0 ) then
				Env.Insert ( name, undefined );
			else
				Env.Insert ( name, Conversion.RowToStructure ( rows ) );
			endif; 
		endif;
	enddo;
	if ( indexExists ) then
		Env.Insert ( "Data", Data );
	endif; 
	
EndProcedure 

Procedure Perform ( Env, CheckAccess = true ) export
	
	if ( not CheckAccess ) then
		SetPrivilegedMode ( true );
	endif;
	SQL.Prepare ( Env );
	SQL.Unload ( Env );
	
EndProcedure 

Function Fetch ( Env, Name ) export
	
	field = "i" + Mid ( Name, 2 );
	index = Env [ field ];
	return Env.Data [ index ].Unload ();
	
EndFunction 

Function Exec ( Q, CheckAccess = true ) export
	
	if ( not CheckAccess ) then
		SetPrivilegedMode ( true );
	endif;
	SQL.DefineTempManager ( Q );
	env = new Structure ();
	tables = CoreLibrary.QueryTables ( q.Text );
	extractData ( tables, env, Q.ExecuteBatch () );
	return env;
	
EndFunction 
