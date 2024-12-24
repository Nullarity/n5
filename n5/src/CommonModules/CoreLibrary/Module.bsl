
Function DateToTime ( Date ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Conversion" ).DateToTime ( SessionParameters.License, Date );
	
EndFunction

Function module ()
	
	return CoreExtension;
	
EndFunction

Function EscapeCSV ( String ) export
	
	//@skip-warning
	return module ().GetLibrary ( "CSV" ).Escape ( String );
	
EndFunction

Procedure AdjustQuery ( Query ) export
	
	//@skip-warning
	Query.Text = module ().GetLibrary ( "Root" ).AdjustQuery ( SessionParameters.License, Query.Text );
	
EndProcedure

Function QueryTables ( Query ) export
	
	//@skip-warning
	return Conversion.FromJSON ( module ().GetLibrary ( "Root" ).QueryTables ( SessionParameters.License, Query ) );
	
EndFunction

Procedure AugmentQuery ( Query ) export
	
	//@skip-warning
	module ().GetLibrary ( "Root" ).AugmentQuery ( SessionParameters.License, Query );
	
EndProcedure

Function VersionToNumber ( Version ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Root" ).VersionToNumber ( Version );
	
EndFunction

Function NumberToVersion ( Release ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Root" ).NumberToVersion ( Release );
	
EndFunction

Function ParseAppearance ( Rules ) export
	
	//@skip-warning
	result = Conversion.FromJSON ( module ().GetLibrary ( "Root" ).ParseAppearance ( SessionParameters.License, StrConcat ( Rules, ";" ) ) );
	if ( TypeOf ( result ) = Type ( "Structure" ) ) then
		raise "Conditional Appearance " + result.Error + " at " + result.Position;
	endif;
	return new FixedArray ( result );
	
EndFunction

Function Chilkat ( Class ) export
	
	//@skip-warning
	return codemodule ().Chilkat ( Class );
	
EndFunction

Function codemodule ()
	
	return CoreFunctions;
	
EndFunction

Function SeriesAndNumber ( Value ) export
	
	//@skip-warning
	result = Conversion.FromJSON ( module ().GetLibrary ( "Root" ).SeriesAndNumber ( Value ) );
	return result;
	
EndFunction

Function Condition1 ( Value1, Value2 ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Collections" ).Condition1 ( SessionParameters.License, Value1, Value2 );
	
EndFunction

Function Condition2 ( Value1, Value2, Value3 ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Collections" ).Condition2 ( SessionParameters.License, Value1, Value2, Value3 );
	
EndFunction

Function KeyColumnValue ( ToExpense, Table1Value ) export
	
	//@skip-warning
	return module ().GetLibrary ( "Collections" ).KeyColumnValue ( SessionParameters.License, ToExpense, Table1Value );
	
EndFunction

Function ExtractFields ( Body ) export
	
	//@skip-warning
	return codemodule ().ExtractFields ( Body );
	
EndFunction

Function BuildPanel ( Parts ) export
	
	//@skip-warning
	return codemodule ().BuildPanel ( Parts );
	
EndFunction

Function GetIssues ( Repository, Token, Since, Status ) export
	
	//@skip-warning
	lib = module ().GetLibrary ( "github" );
	try
		return lib.Issues ( Repository, Token, Since, Status );
	except
		raise lib.Problem ();
	endtry;
	
EndFunction

Function MarkdownToHTML ( String ) export
	
	return module ().GetLibrary ( "Conversion" ).MarkdownToHTML ( String );
	
EndFunction

Function CleanAnthropicAnswer ( String ) export
	
	return module ().GetLibrary ( "Root" ).CleanAnthropicAnswer ( String );
	
EndFunction

Function GetArea ( Text, Area ) export
	
	lib = module ().GetLibrary ( "Root" );
	return lib.GetArea ( Text, Area );
	
EndFunction

Function RomanianToLatin ( String ) export
	
	return module ().GetLibrary ( "Root" ).RomanianToLatin ( String );
	
EndFunction

Function CyrillicToRomanian ( String ) export
	
	return module ().GetLibrary ( "Root" ).CyrillicToRomanian ( String );
	
EndFunction

Function HasCyrillic ( String ) export
	
	return module ().GetLibrary ( "Root" ).HasCyrillic ( String );
	
EndFunction

Function FuzzyMatch ( List, MatchColumn, WithText ) export
	
	json = module ().GetLibrary ( "Root" ).FuzzyMatch (
		Conversion.ToJSON ( List ), MatchColumn, WithText );
	return Conversion.FromJSON ( json );
	
EndFunction

