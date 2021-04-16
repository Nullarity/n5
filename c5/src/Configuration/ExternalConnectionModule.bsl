
Procedure OnStart ()
	
	if ( Logins.Rooted () ) then
		return;
	endif;
	computer = ComputerName ();
	webClient = false;
	mobileClient = false;
	thinClient = false;
	thickClient = true;
	linux = Framework.IsLinux ();
	StartingSrv.NewSession ( computer, webClient, mobileClient, thinClient, thickClient, linux );
	
EndProcedure
