#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Base;
var Env;

Procedure Filling ( FillingData, StandardProcessing )
	
	Base = FillingData;
	if ( TypeOf ( Base ) = Type ( "Structure" )
		and Base.Property ( "RenewTenantOrder" ) ) then
		fillByOrderNumber ();
	endif;

EndProcedure

Procedure fillByOrderNumber ()
	
	initEnv ();
	getPreviousOrderData ();
	fillByPreviousOrder ();
	
EndProcedure

Procedure initEnv ()
	
	Env = new Structure ();
	SQL.Init ( Env );
	
EndProcedure

Procedure getPreviousOrderData ()
	
	sqlPreviousOrderData ();
	Env.Q.SetParameter ( "PreviousOrderNumber", Base.RenewTenantOrder );
	Env.Q.SetParameter ( "Tenant", SessionParameters.Tenant );
	SQL.Perform ( Env );
	if ( Env.Fields = undefined ) then
		raise Output.TenantOrderNotFound ( new Structure ( "OrderNumber", Base.RenewTenantOrder ) );
	endif; 
	
EndProcedure

Procedure sqlPreviousOrderData ()
	
	s = "
	|// @Fields
	|select dateadd ( Document.DateEnd, day, 1 ) as Date, Document.MonthsCount as MonthsCount, Document.UsersCount as UsersCount
	|from Document.TenantOrder as Document
	|where Document.Number = &PreviousOrderNumber
	|and Document.Tenant = &Tenant
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure fillByPreviousOrder ()
	
	today = BegOfDay ( CurrentSessionDate () );
	Date = Max ( today, Env.Fields.Date );
	MonthsCount = Env.Fields.MonthsCount;
	UsersCount = Env.Fields.UsersCount;
	
EndProcedure 

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( not checkDate () ) then
		Cancel = true;
		return;
	endif; 
	
EndProcedure

Function checkDate ()
	
	today = BegOfDay ( CurrentSessionDate () );
	if ( Date <> Date ( 1, 1, 1 ) and Date < today ) then
		Output.LicenseDateStartError ( , "Date" );
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )
	
	if ( DataExchange.Load ) then
		return;
	endif; 
	if ( Posted ) then
		if ( not canBeChanged () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	if ( DeletionMark ) then
		if ( not canBeDeleted () ) then
			Cancel = true;
			return;
		endif; 
	endif; 
	
EndProcedure

Function canBeChanged ()
	
	if ( IsInRole ( "AdministratorSystem" ) ) then
		return true;
	endif; 
	Output.TenantOrderCannotBeChanged ();
	return false;
	
EndFunction 

Function canBeDeleted ()
	
	if ( IsInRole ( "AdministratorSystem" ) ) then
		return true;
	endif; 
	if ( Documents.TenantOrder.Paid ( Ref ) ) then
		Output.TenantOrderDeletionError ();
		return false;
	endif; 
	return true;
	
EndFunction 

Procedure Posting ( Cancel, PostingMode )
	
	Env = Posting.GetParams ( Ref, RegisterRecords );
	Cancel = not Documents.TenantOrder.Post ( Env );
	
EndProcedure

#endif