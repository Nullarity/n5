#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure Unsync ( Ref ) export
	
	r = InformationRegisters.Assistants.CreateRecordManager ();
	r.Assistant = Ref;
	r.Read ();
	if ( r.Selected () ) then
		r.Synced = false;
		r.Write ();
	endif;
	
EndProcedure

#endif