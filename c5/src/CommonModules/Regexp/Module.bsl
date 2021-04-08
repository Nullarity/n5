Function Select ( From, How ) export
	
	//@skip-warning
	exp = CoreExtension.GetLibrary ( "Regex" );
	result = exp.Select ( From, How );
	return Conversion.FromJSON ( result );

EndFunction

Function Test ( What, How ) export
	
	//@skip-warning
	exp = CoreExtension.GetLibrary ( "Regex" );
	return exp.Test ( What, How );

EndFunction

Function Replace ( What, How, Replacement ) export
	
	//@skip-warning
	exp = CoreExtension.GetLibrary ( "Regex" );
	return exp.Replace ( What, How, Replacement );

EndFunction