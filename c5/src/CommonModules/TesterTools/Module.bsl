Procedure Error ( Object, Msg ) export
	
	name = Object.Metadata ().Name;
	Message ( name + ": " + Msg );
	
EndProcedure 

&AtServer
Procedure Record ( Test ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.TesterRecorder.CreateRecordManager ();
	r.Test = Test;
	r.Write ();
	
EndProcedure
