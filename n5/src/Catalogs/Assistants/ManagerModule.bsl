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

Function FindByID ( ID ) export
	
	q = new Query ( "select Assistant from InformationRegister.Assistants where ID = &ID" );
	q.SetParameter ( "ID", ID );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Assistant );
	
EndFunction

#endif