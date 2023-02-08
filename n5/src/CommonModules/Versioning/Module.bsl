
Procedure FlushHistory() export
	
	splitted = SessionParameters.TenantUse;
	SessionParameters.TenantUse = false;
	DataHistory.UpdateHistory ();
	SessionParameters.TenantUse = splitted;
	
EndProcedure
