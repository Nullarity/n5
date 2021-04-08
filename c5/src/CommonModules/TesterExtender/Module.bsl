
Function TestingOn ( Test ) export
	
	on = TesterCache.Testing ();
	if ( on ) then
		TesterTools.Record ( Test );
	endif;
	return on;
	
EndFunction

Function ТестированиеВкл ( Test ) export
	
	return TestingOn ( Test );
	
EndFunction

Function TestingOff ( Test ) export
	
	return not TestingOn ( Test );
	
EndFunction

Function ТестированиеВыкл ( Test ) export
	
	return TestingOff ( Test );
	
EndFunction

Function Assert ( Value, Details = "" ) export 
	
	#if ( Server ) then
		obj = DataProcessors.Tester.Create ();
	#else
		obj = GetForm ( "DataProcessor.Tester.Form.Assertions" );
	#endif
	obj.That ( Value, Details );	
	return obj;
	
EndFunction

Function Заявить ( Value, Details = "" ) export
	
	return Assert ( Value, Details );
	
EndFunction
