#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Errors;
var OriginalTenant;
var OldTenants;
var DeletionMark;
var Membership;

Procedure Exec () export
	
	init ();
	for each tenant in Catalogs.Membership.GetTenants ( Parameters.Membership ) do
		activate ( tenant );
		if ( DeletionMark ) then
			cancel ();
		else
			update ( getUsers () );
		endif;
		release ( tenant );
	enddo;
	if ( Errors.Count () = 0 ) then
		revoke ();
	else
		activate ( OriginalTenant );
		Progress.Put ( StrConcat ( Errors, Chars.LF ), JobKey, true );
	endif;

EndProcedure

Procedure init ()
	
	Membership = Parameters.Membership;
	DeletionMark = DF.Pick ( Membership, "DeletionMark" );
	Errors = new Array ();
	OriginalTenant = SessionParameters.Tenant;
	OldTenants = Parameters.OldTenants;

EndProcedure

Procedure activate ( Tenant )
	
	try
		SessionParameters.Tenant = Tenant;
	except
		Progress.Put ( BriefErrorDescription ( ErrorInfo () ), JobKey, true );
		raise Output.OperationNotPerformed ();
	endtry;
	
EndProcedure

Function getUsers ()

	s = "select Memberships.User as User
	|from InformationRegister.Membership as Memberships
	|where Memberships.Membership = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Membership );
	return q.Execute ().Unload ().UnloadColumn ( "User" );
	
EndFunction

Procedure release ( Tenant )
	
	if ( OldTenants = undefined ) then
		return;
	endif;
	i = OldTenants.Find ( Tenant );
	if ( i <> undefined ) then
		OldTenants.Delete ( i );
	endif;

EndProcedure

Procedure cancel ()

	BeginTransaction ();
	try
		ok = Catalogs.Membership.Unpost ( Membership );
	except
		error = BriefErrorDescription ( ErrorInfo () );
		RollbackTransaction ();
		addError ( error );
		return;
	endtry;
	if ( not ok ) then
		error = Output.OperationError ();
		RollbackTransaction ();
		addError ( error );
		return;
	endif;
	CommitTransaction ();
	
EndProcedure

Procedure update ( Users )

	BeginTransaction ();
	try
		ok = Catalogs.Membership.Post ( Membership, Users );
	except
		error = BriefErrorDescription ( ErrorInfo () );
		RollbackTransaction ();
		addError ( error );
		return;
	endtry;
	if ( not ok ) then
		error = Output.OperationError ();
		RollbackTransaction ();
		addError ( error );
		return;
	endif;
	CommitTransaction ();
	
EndProcedure

Procedure addError ( Description )
	
	msg = new Structure ( "Tenant, Error", SessionParameters.Tenant, Description );
	Errors.Add ( Output.UserAccessChangingError ( msg ) );
	
EndProcedure

Procedure revoke ()
	
	if ( OldTenants = undefined ) then
		return;
	endif;
	nousers = new Array ();
	for each tenant in OldTenants do
		activate ( tenant );
		update ( nousers );
	enddo;
	
EndProcedure

#endif
