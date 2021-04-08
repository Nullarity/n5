
Procedure Send ( val Reference, val Text, val Receiver ) export
	
	p = new Array ();
	p.Add ( Reference );
	p.Add ( Text );
	p.Add ( Receiver );
	Jobs.Run ( "UserCollaborationSrv.Send", p, , , TesterCache.Testing () );
	
EndProcedure

