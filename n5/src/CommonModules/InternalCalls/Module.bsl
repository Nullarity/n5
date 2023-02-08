
Function GetLibrary () export
	
	//@skip-warning
	return module ().GetLibrary ( "Root" );
	
EndFunction

Function module ()
	
	return CoreExtension;
	
EndFunction

Procedure SetLicense ( Data ) export
	
	//@skip-warning
	module ().SetLicense ( Mid ( Data, 1, StrLen ( Data ) - 1 ) );
	
EndProcedure

Procedure WriteSuccessfull ( Email ) export
	
	MailboxesSrv.WriteSuccessfull ( Email );
	
EndProcedure

Procedure SQLInit ( Env ) export
	
	SQL.Init ( Env );
	
EndProcedure

Procedure Perform ( Env ) export
	
	SQL.Perform ( Env );
	
EndProcedure