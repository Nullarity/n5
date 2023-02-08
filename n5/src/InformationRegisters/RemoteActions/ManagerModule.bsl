#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Function Create ( Action, P1 = undefined, P2 = undefined, Expire = undefined ) export

	r = CreateRecordManager ();
	id = new UUID ();
	r.ID = id;
	r.Action = Action;
	r.Parameter1 = P1;
	r.Parameter2 = P2;
	r.Expire = ? ( Expire = undefined, CurrentSessionDate () + Enum.ConstantsRemoteActionExpiration (), Expire );
	r.Write ();
	return Cloud.RemoteActionsService () + "/hs/RemoteActions?ID=" + id;
	
EndFunction

#endif