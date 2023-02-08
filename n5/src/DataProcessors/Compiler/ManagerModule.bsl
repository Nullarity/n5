#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Syntax ( Script ) export
	
	processor = Create ();
	processor.Script = Script;
	return processor.SyntaxCode ();
	
EndFunction

Function Compile ( Script ) export
	
	processor = Create ();
	processor.Script = Script;
	return processor.Compile ();
	
EndFunction

#endif