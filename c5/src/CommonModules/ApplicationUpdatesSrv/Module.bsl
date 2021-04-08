
Function NewUpdates () export
	
	return Constants.NewUpdates.Get ();
	
EndFunction

Procedure Logging ( val Error ) export
	
	WriteLogEvent ( "ApplicationUpdates.Check", EventLogLevel.Error, , , Error );

EndProcedure

Function License () export
	
	return Constants.License.Get ();
	
EndFunction

Function MyRelease () export
	
	return CoreLibrary.VersionToNumber ( Metadata.Version );
	
EndFunction

Function BodyToStructure ( val Body ) export
	
	return Conversion.FromJSON ( Body );
	
EndFunction

