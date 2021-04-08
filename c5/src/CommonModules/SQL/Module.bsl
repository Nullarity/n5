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
	defineTempManager ( q );
	Env.Selection = new Array ();

EndProcedure 

Procedure defineTempManager ( Q )
	
	if ( Find ( Q.Text, "into " ) > 0 ) then
		if ( Q.TempTablesManager = undefined ) then
			Q.TempTablesManager = new TempTablesManager ();
		endif; 
	endif; 
	
EndProcedure 

Procedure Unload ( Env, Data = undefined ) export

	q = Env.Q;
	result = ? ( Data = undefined, q.ExecuteBatch (), Data );
	extractData ( q, Env, result );
	
EndProcedure

Procedure extractData ( Q, Env, Data )
	
	indexExists = false;
	list = CoreLibrary.QueryTables ( Q.Text );
	for each table in list do
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

Function Exec ( Q ) export
	
	defineTempManager ( Q );
	env = new Structure ();
	extractData ( Q, env, Q.ExecuteBatch () );
	return env;
	
EndFunction 
