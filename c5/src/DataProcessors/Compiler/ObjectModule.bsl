#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Script export;
var Syntax;
var Compiled;
var Program;
var Procedures;
var CurrentRow;
var ProcedureStarts;
var ProcedureEnds;
var ParametersLimit;

Function Compile () export
	
	init ();
	enumerate ();
	compileProcedures ( Program, false );
	assemble ();
	return Compiled;
	
EndFunction

Procedure init ()
	
	Program = new Array ();
	
EndProcedure 

Procedure syntax ()
	
	rows = StrSplit ( Script, Chars.LF );
	compileProcedures ( rows, true );
	fixReturn ( rows, true );
	compose ( rows );
	
EndProcedure

Procedure compose ( Scope )
	
	Syntax = "if ( false ) then " + StrConcat ( Scope, Chars.LF ) + Chars.LF + "endif;";
	
EndProcedure 

Procedure fixReturn ( Scope, SyntaxOnly )
	
	running = not SyntaxOnly;
	for i = 0 to Scope.UBound() do
		row = Scope[i];
		pattern = "((^\s+)|^)(return;|возврат;|return\s+;|возврат\s+;)";
		if (Regexp.Test(row, pattern)) then
			if ( running ) then
				Scope[i] = Regexp.Replace(row, pattern, "$1goto ~_return;");
			else
				Scope[i] = Regexp.Replace(row, pattern, "$1");
			endif;
		else
			pattern = "((^\s+)|^)(return\s+|возврат\s+)";
			if (Regexp.Test(row, pattern)) then
				Scope[i] = Regexp.Replace(row, pattern, "$1result = ");
				if (running) then
					Scope.Insert(i + 1, "goto ~_return;");
				endif;
			endif;
		endif;
	enddo;
	
EndProcedure 

Procedure finalize ( Scope )
	
	s = "
	|~_return:";
	Scope.Add ( s );
	
EndProcedure 

Procedure enumerate ()
	
	rows = StrSplit ( Script, Chars.LF );
	for each row in rows do
		if ( IsBlankString ( row ) ) then
			continue;
		endif; 
		Program.Add ( row );
	enddo; 
	
EndProcedure 

Procedure compileProcedures ( Scope, SyntaxOnly )
	
	extractProcedures ( Scope, SyntaxOnly );
	replaceCalls ( Scope );
	if ( not SyntaxOnly ) then
		prepareProcedures ();
	endif; 
	
EndProcedure 

Procedure extractProcedures ( Scope, SyntaxOnly )
	
	details = undefined;
	begin = false;
	Procedures = new Array ();
	for i = 0 to Scope.UBound () do
		if ( not rowDefined ( Scope, i ) ) then
			continue;
		endif; 
		if ( begin ) then
			end = procedureFinishes ( details, i );
		else
			details = procedureBegins ( Scope, i );
			if ( details <> undefined ) then
				begin = true;
				end = false; 
				params = details.Params;
				if ( SyntaxOnly ) then
					declareParams ( Scope, i, params );
				else
					proceduresScript = details.Script;
				endif; 
				Procedures.Add ( details );
			endif; 
		endif; 
		if ( begin ) then
			if ( SyntaxOnly ) then
				if ( end ) then
					Scope [ i ] = "";
				endif; 
			else
				if ( i > params.Line
					and not end ) then
					proceduresScript.Add ( Scope [ i ] );
				endif; 
				Scope [ i ] = "";
			endif; 
		endif; 
		begin = begin and not end;
	enddo; 
	
EndProcedure

Function rowDefined ( Scope, Line )
	
	row = Scope [ Line ];
	if ( IsBlankString ( row ) ) then
		return false;
	endif; 
	CurrentRow = TrimAll ( Lower ( row ) );
	return true;
	
EndFunction 

Function procedureBegins ( Scope, Line )
	
	descriptor = procDeclaration ();
	if ( descriptor = undefined ) then
		return undefined;
	endif; 
	name = procName ( Scope, Line, descriptor.Len );
	if ( name = undefined ) then
		return undefined;
	endif; 
	params = procParams ( Scope, name );
	return new Structure ( "Name, Function, Params, Script, Start, End", name, descriptor.Function, params, new Array (), Line, Line );
	
EndFunction

Function procDeclaration ()
	
	for each item in ProcedureStarts do
		if ( StrStartsWith ( CurrentRow, item.Key ) ) then
			descriptor = item.Value;
			next = Mid ( CurrentRow, descriptor.Len, 1 );
			if ( next = ""
				or next = " " ) then
				return descriptor;
			endif; 
		endif; 
	enddo; 
	
EndFunction 

Function procName ( Scope, Line, NameBegins )
	
	for i = Line to Scope.UBound () do
		normal = Lower ( Scope [ i ] );
		s = TrimAll ( Mid ( normal, NameBegins ) );
		if ( s = "" ) then
			i = i + 1;
			NameBegins = 1;
		else
			nameEnds = StrFind ( s, "(" );
			if ( nameEnds = 0 ) then
				nameEnds = StrLen ( s );
			endif; 
			name = TrimAll ( Left ( s, nameEnds - 1 ) );
			return new Structure ( "Name, Line, End, Len", name, i, nameEnds, StrLen ( name ) );
		endif; 
	enddo;
	
EndFunction 

Function procParams ( Scope, Name )
	
	list = "";
	started = false;
	finished = false;
	nameEnds = Name.End;
	for i = Name.Line to Scope.UBound () do
		row = Scope [ i ];
		if ( started ) then
			paramsStart = 1;
		else
			paramsStart = 1 + StrFind ( row, "(", , nameEnds );
			if ( paramsStart > 1 ) then
				started = true;
			else
				nameEnds = 1;
			endif; 
		endif; 
		paramsEnd = StrFind ( row, ")", SearchDirection.FromEnd );
		if ( paramsEnd = 0 ) then
			paramsEnd = StrLen ( row );
		else
			finished = true;
		endif; 
		if ( started ) then
			list = list + Mid ( row, paramsStart, paramsEnd - paramsStart );
		endif; 
		if ( finished ) then
			params = Conversion.StringToStructure ( list, "=", "," );
			if ( params.Count () > ParametersLimit ) then
				raise Output.ParametersCountError ( new Structure ( "Name, Limit", Name.Name, ParametersLimit ) );
			endif; 
			result = new Structure ();
			result.Insert ( "Line", i );
			result.Insert ( "Params", params );
			result.Insert ( "Loader", paramsLoader ( params ) );
			return result;
		endif; 
		i = i + 1;
	enddo; 
	
EndFunction 

Function paramsLoader ( Params )
	
	loader = "";
	counter = 1;
	for each param in Params do
		incomingParam = "_P" + counter;
		value = param.Value;
		defaultValue = ? ( ValueIsFilled ( value ), value, "undefined" );
		loader = loader + param.Key + " = ? ( " + incomingParam + " = undefined, " + defaultValue + ", " + incomingParam + ");";
		counter = counter + 1;
	enddo; 
	return loader;
	
EndFunction 

Procedure declareParams ( Scope, Line, Params )
	
	declaration = "";
	for each param in Params.Params do
		declaration = declaration + param.Key + " = undefined;";
	enddo; 
	Scope [ Line ] = declaration;
	for i = Line + 1 to Params.Line do
		Scope [ i ] = "";
	enddo; 
	
EndProcedure 

Function procedureFinishes ( Details, Line )
	
	if ( ProcedureEnds.Find ( CurrentRow ) <> undefined ) then
		Details.End = Line;
		return true;
	else
		return false;
	endif;
	
EndFunction 

Procedure replaceCalls ( Scope )
	
	for i = 0 to Scope.UBound () do
		row = Scope [ i ];
		if ( IsBlankString ( row ) ) then
			continue;
		endif; 
		for each proc in Procedures do
			name = proc.Name;
			procName = name.Name;
			count = proc.Params.Params.Count ();
			valve = ? ( proc.Function, "Runtime.DeepFunction", "Runtime.DeepProcedure" );
			caller = valve + " ( _procedures, """ + procName + """" + ? ( count = 0, " ", ", " );
			pattern = "(^| +|\t+|=|\+|-|;|/|\*|\\|\,|%|\(|\))(" + procName + "( +|\t+|)\()";
			if (Regexp.Test(row, pattern)) then
				row = Regexp.Replace(row, pattern, "$1" + caller);
			endif;
		enddo; 
		Scope [ i ] = row;
	enddo; 
	
EndProcedure 

Procedure prepareProcedures ()
	
	for each proc in Procedures do
		rows = proc.Script;
		rows.Insert ( 0, proc.Params.Loader );
		replaceCalls ( rows );
		fixReturn ( rows, false );
		finalizeProcedure ( rows );
	enddo; 
	
EndProcedure 

Procedure finalizeProcedure ( Scope )
	
	Scope.Add ( "~_return:" );
		
EndProcedure 

Procedure assemble ()
	
	Program.Insert ( 0, getProcedures () );	
	fixReturn ( Program, false );
	finalize ( Program );
	Compiled = StrConcat ( Program, Chars.LF );
	
EndProcedure 

Function getProcedures ()
	
	enter = Chars.LF;
	splitter = enter + "|";
	list = new Array ();
	for each proc in Procedures do
		code = StrConcat ( proc.Script, splitter );
		s = "_procedures [ """ + proc.Name.Name + """ ] = """ + StrReplace ( code, """", """""" ) + """;";
		list.Add ( s );
	enddo; 
	return StrConcat ( list, enter );

EndFunction 

Function SyntaxCode () export
	
	syntax ();
	return Syntax;
	
EndFunction

// *****************************************
// *********** Variables Initialization

ProcedureStarts = new Map ();
ProcedureStarts [ "процедура" ] = new Structure ( "Len, Function", 10, false );
ProcedureStarts [ "procedure" ] = new Structure ( "Len, Function", 10, false );
ProcedureStarts [ "функция" ] = new Structure ( "Len, Function", 8, true );
ProcedureStarts [ "function" ] = new Structure ( "Len, Function", 9, true );

ProcedureEnds = new Array ();
ProcedureEnds.Add ( "конецпроцедуры" );
ProcedureEnds.Add ( "endprocedure" );
ProcedureEnds.Add ( "конецфункции" );
ProcedureEnds.Add ( "endfunction" );

ParametersLimit = 20;

#endif