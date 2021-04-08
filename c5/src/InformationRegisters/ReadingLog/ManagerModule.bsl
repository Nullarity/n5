#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Add ( Document, Memo = undefined ) export
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.ReadingLog.CreateRecordManager ();
	r.User = SessionParameters.User;
	r.Document = Document;
	r.Date = CurrentSessionDate ();
	r.ID = new UUID ();
	r.Memo = Memo;
	r.Write ();
	SetPrivilegedMode ( false );
	
EndProcedure 

#endif