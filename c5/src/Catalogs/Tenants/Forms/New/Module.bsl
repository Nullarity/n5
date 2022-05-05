// *****************************************
// *********** Form events

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )

	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|WrongName show WrongName;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure OK ( Command )
	
	if ( WrongName
		or not CheckFilling () ) then
		return;
	endif;
	start ();
	Progress.Open ( UUID, , new NotifyDescription ( "CreationCompleted", ThisObject ), true,
		Enum.ShowMessagesInSeparateWindow () );
	
EndProcedure

&AtServer
Procedure start ()
	
	p = DataProcessors.CreateTenant.GetParams ();
	p.Company = Organization;
	p.User = UserName ();
	p.Creator = SessionParameters.Login;
	ResultAddress = PutToTempStorage ( undefined, UUID );
	p.Result = ResultAddress;
	args = new Array ();
	args.Add ( "CreateTenant" );
	args.Add ( p );
	Jobs.Run ( "Jobs.ExecProcessor", args, UUID, , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure CreationCompleted ( Result, Params ) export
	
	if ( Result = false ) then
		return;
	endif;
	NotifyWritingNew ( GetFromTempStorage ( ResultAddress ) );
	Close ();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange ( Item )

	updateWarning ( ThisObject );
	if ( WrongName ) then
		CurrentItem = Item;
	endif;

EndProcedure

&AtClient
Procedure updateWarning ( Form )
	
	if ( Organization = "" ) then
		WrongName = false;		
	else
		WrongName = undefined <> DF.GetOriginal ( PredefinedValue ( "Catalog.Tenants.EmptyRef" ), "Description", Organization );		
	endif;
	Appearance.Apply ( Form, "WrongName" );
	
EndProcedure
