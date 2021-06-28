Procedure Go () export

	if ( SessionInfo.UpdateRequired ) then
		if ( SessionInfo.Sysadmin ) then
			mode = LaunchParameters [ Enum.LaunchParametersMode () ];
			if ( mode = Enum.LaunchParametersSkipUpdate () ) then
				onStart ();
			else
				OpenForm ( "DataProcessor.UpdateInfobase.Form", , , , , , new NotifyDescription ( "StartUpdate", ThisObject ) );
			endif;
		else
			raise Output.UpdateNotPermitted ();
		endif;
	else
		Starting.Unlockdb ();
		onStart ();
	endif;
	
EndProcedure

Procedure StartUpdate ( Result, Params ) export
	
	Starting.Unlockdb ();
	if ( Result = undefined ) then
		Exit ( false );
		return;
	endif;
	error = undefined;
	id = StartingSrv.RunUpdate ( error );
	if ( error = undefined ) then
		Progress.Open ( id, , new NotifyDescription ( "UpdateComplete", ThisObject ), true );
	else
		Output.ShowError ( ThisObject, , error );
	endif;
	
EndProcedure

Procedure UpdateComplete ( Result, Params ) export
	
	if ( Result ) then
		OpenForm ( "DataProcessor.UpdateInfobase.Form.Complete", , , , , , new NotifyDescription ( "AfterUpdate", ThisObject ) );
	else
		Exit ( false );
	endif;
	
EndProcedure

Procedure ShowError ( Result ) export
	
	Exit ( false );
	
EndProcedure

Procedure AfterUpdate ( Result, Params ) export
	
	onStart ();
	
EndProcedure

Procedure Unlockdb () export
	
	mode = LaunchParameters [ Enum.LaunchParametersMode () ];
	if ( mode = Enum.LaunchParametersUpdateApplied ()
		or mode = Enum.LaunchParametersUpdateCanceled () ) then
		StartingSrv.UnlockDB ();
	endif;
		
EndProcedure

Procedure onStart ()
	
	if ( SessionInfo.Cloud ) then
		if ( StartingSrv.TenantDeactivated () ) then
			p = new Structure ( "Info", StartingSrv.Info () );
			Output.ProfileDeactivated ( ThisObject, , p, "Quit" );
			return;
		endif; 
		startCloudSession ();
	else
		afterStartCloudSession ();
	endif;
	
EndProcedure

Procedure Quit ( Params ) export
	
	Terminate ();
	
EndProcedure 

Procedure startCloudSession ()
	
	if ( SessionInfo.Unlimited
		or SessionInfo.Testing ) then
		afterStartCloudSession ();
	else
		anotherSessions = StartingSrv.GetCopies ();
		if ( anotherSessions = undefined ) then
			afterStartCloudSession ();
		else
			s = StrConcat ( AnotherSessions, Chars.LF );
			Output.AnotherSessionDetected ( ThisObject, , new Structure ( "Sessions", s ), "AnotherSessionDetected" );
		endif; 
	endif; 
	
EndProcedure 

Procedure AnotherSessionDetected ( Answer, Params ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		StartingSrv.DisconnectCopies ();
		afterStartCloudSession ();
	else
		Terminate ();
	endif;
	
EndProcedure 

Procedure afterStartCloudSession ()
	
	if ( SessionInfo.AccessDenied
		or SessionInfo.AccessRevoked ) then
		Output.AccessDenied ( ThisObject, , , "Quit" );
		return;
	endif; 
	userChangePassword ();
	
EndProcedure 

Procedure userChangePassword ()
	
	if ( SessionInfo.MustChangePassword ) then
		p = new Structure ( "ChangePasswordBeforeStartApplication", true );
		OpenForm ( "Catalog.Users.Form.ChangePassword", p, , , , , new NotifyDescription ( "ChangePassword", ThisObject ), FormWindowOpeningMode.LockWholeInterface );
	else
		afterUserChangePassword ();
	endif; 
	
EndProcedure

Procedure ChangePassword ( Result, Params ) export
	
	if ( Result = undefined or not Result ) then
		Terminate ();
	else
		afterUserChangePassword ();
	endif; 
	
EndProcedure 

Procedure afterUserChangePassword ()
	
	setTitle ();
	if ( SessionInfo.Cloud ) then
		paymentInfo = CloudPayments.GetInfo ();
		if ( userMustPay ( paymentInfo ) ) then
			payOrder ( paymentInfo );
		else
			afterPayOrder ();
		endif; 
	else
		startSession ();
	endif;
	
EndProcedure

Procedure setTitle ( UnreadEmails = 0 )
	
	LoggedUser = UserName ();
	SetAppCaption ();
	
EndProcedure 

Function userMustPay ( PaymentInfo )
	
	return not PaymentInfo.System
	and PaymentInfo.Today > PaymentInfo.EndOfTrialPeriod
	and PaymentInfo.UsersCount > PaymentInfo.PaidUsersCount;
		
EndFunction 

Procedure payOrder ( PaymentInfo )
	
	if ( CloudPayments.UserCanPay () ) then
		Output.StartPaymentProcessConfirmation ( ThisObject, PaymentInfo, PaymentInfo );
	else
		Output.Debt ( ThisObject, , , "Quit" );
	endif; 
	
EndProcedure

Procedure StartPaymentProcessConfirmation ( Answer, PaymentInfo ) export
	
	if ( Answer = DialogReturnCode.Yes ) then
		openTenantOrder ( PaymentInfo );
	else
		Terminate ();
	endif; 
	
EndProcedure 

Procedure openTenantOrder ( PaymentInfo )
	
	p = new Structure ( "FillingValues", new Structure () );
	p.FillingValues.Insert ( "UsersCount", PaymentInfo.UsersCount - PaymentInfo.PaidUsersCount );
	p.FillingValues.Insert ( "MonthsCount", 3 );
	OpenForm ( "Document.TenantOrder.ObjectForm", p, , , , , new NotifyDescription ( "TenantOrderObjectForm", ThisObject ), FormWindowOpeningMode.LockWholeInterface );

EndProcedure 

Procedure TenantOrderObjectForm ( Result, Params ) export
	
	newPaymentInfo = CloudPayments.GetInfo ();
	if ( userMustPay ( newPaymentInfo ) ) then
		payOrder ( newPaymentInfo );
	else
		afterPayOrder ();
	endif; 
	
EndProcedure 

Procedure afterPayOrder ()
	
	c1 = LaunchParameters [ "c1" ];
	if ( c1 = undefined ) then
		startSession ();
	else
		renewTenantOrder ( LaunchParameters.c1 );
	endif;
	
EndProcedure 

Procedure renewTenantOrder ( OrderNumber )
	
	if ( CloudPayments.UserCanPay () ) then
		p = new Structure ( "FillingValues", new Structure () );
		p.FillingValues.Insert ( "RenewTenantOrder", OrderNumber );
		OpenForm ( "Document.TenantOrder.ObjectForm", p, , , , , new NotifyDescription ( "MakeUpAccount", ThisObject ), FormWindowOpeningMode.LockWholeInterface );
	else
		Output.TenantOrderAccessError ( ThisObject );
	endif; 
	
EndProcedure 

Procedure MakeUpAccount ( Result, Params ) export
	
	startSession ();
	
EndProcedure 

Procedure TenantOrderAccessError ( Params ) export
	
	startSession ();
	
EndProcedure 

Procedure startSession ()
	
	if ( SessionInfo.FirstStart ) then
		OpenForm ( "CommonForm.Settings", , , , , , new NotifyDescription ( "ApplicationSettingsForm", ThisObject ), FormWindowOpeningMode.LockWholeInterface );
	else
		checkLicense ();
	endif; 
	
EndProcedure 

Procedure ApplicationSettingsForm ( Result, Params ) export
	
	checkLicense ();
	
EndProcedure 

Procedure checkLicense ()
	
	status = StartingSrv.CheckLicense ();
	if ( status <> Enum.LicensingOK () ) then
		runDemo ();
	endif;
	if ( status = Enum.LicensingError ()
		or status = Enum.LicensingLicenseNotFound () ) then
		if ( SessionInfo.Admin ) then
			OpenForm ( "CommonForm.ResetKey", , , , , , new NotifyDescription ( "AfterKeyResetting", ThisObject ) );
			return;
		endif;
	endif;
	if ( StartingSrv.SetFirstLogin () ) then
		// Insert your code
		// OpenHelp ( "Configuration" );
	endif; 
	if ( SessionInfo.CheckUpdates ) then
		StartUpdatesChecking ();
	endif;
	
EndProcedure 

Procedure runDemo ()
	
	Output.SystemInDemoMode ();
	AttachIdleHandler ( "DemoSessionWarning1", 3300, true );
	
EndProcedure

Procedure DemoSessionExpired ( Result, Stage ) export
	
	if ( Stage = 1 ) then
		AttachIdleHandler ( "DemoSessionWarning2", 300, true );
	else
		Terminate ();
	endif;
	
EndProcedure

Procedure AfterKeyResetting ( Applied, Params ) export
	
	if ( Applied <> undefined ) then
		Exit ( , true );
	endif;
	
EndProcedure
