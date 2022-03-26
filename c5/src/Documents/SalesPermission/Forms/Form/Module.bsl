&AtServer
var Base;
&AtServer
var IsNew;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )

	updateChangesPermission ();

EndProcedure

&AtServer
Procedure updateChangesPermission ()

	Constraints.ShowAccess ( ThisObject );

EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	Base = Parameters.Document;
	IsNew = Object.Ref.IsEmpty ();
	if ( Base = undefined ) then
		if ( IsNew ) then
			raise Output.InteractiveCreationForbidden ();
		endif;
	else
		fill ();
	endif;
	readAppearance ();
	Appearance.Apply ( ThisObject );

EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Expired show Object.Resolution = Enum.AllowDeny.Allow;
	|FormOK show Changed;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

#region Filling

&AtServer
Procedure fill ()
	
	data = baseData ();
	Object.Date = CurrentSessionDate ();
	Object.Document = Base;
	Object.Amount = data.Amount;
	Object.Currency = data.Currency;
	Object.Customer = data.Customer;
	Object.Company = data.Company;
	Object.Creator = SessionParameters.User;
	Object.Responsible = undefined;
	Object.Resolution = undefined;
	table = Object.Restrictions;
	reason = Parameters.Reason;
	rows = table.FindRows ( new Structure ( "Reason", reason ) );
	if ( rows.Count () = 0 ) then
		row = table.Add ();
		row.Reason = reason;
	endif;
	Changed = true;

EndProcedure

&AtServer
Function baseData ()
	
	list = new Array ();
	list.Add ( "Company" );
	list.Add ( "Customer" );
	list.Add ( "Currency" );
	list.Add ( "Amount" );
	type = TypeOf ( Base );
	if ( type = Type ( "DocumentRef.Invoice" )
		or type = Type ( "DocumentRef.SalesOrder" )
		or type = Type ( "DocumentRef.Quote" )
	) then
		list.Add ( "Contract" );
	endif;
	return DF.Values ( Base, StrConcat ( list, "," ) );

EndFunction

#endregion

&AtClient
Procedure NotificationProcessing ( EventName, Parameter, Source )
	
	if ( EventName = Enum.MessageChangesPermissionIsSaved ()
		and ( Parameter = Object.Ref
			or Parameter = BegOfDay ( Object.Date ) ) ) then
		updateChangesPermission ();
	endif;

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	if ( Object.Resolution.IsEmpty () ) then
		sendRequest ();
	else
		PermissionForm.SendSalesResponse ( Object );
	endif;
	
EndProcedure

&AtServer
Procedure sendRequest ()
	
	params = new Array ();
	params.Add ( Object.Ref );
	params.Add ( fullReason () );
	Jobs.Run ( "SalesPermissionMailing.Send", params, , , TesterCache.Testing () );
	
EndProcedure

&AtServer
Function fullReason ()
	
	parts = new Array ();
	for each row in Object.Restrictions do
		parts.Add ( String ( row.Reason ) );
	enddo;
	return StrConcat ( parts, ", " );

EndFunction

&AtClient
Procedure AfterWrite ( WriteParameters )

	Notify ( Enum.MessageSalesPermissionIsSaved (), Object.Document );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ResolutionOnChange ( Item )
	
	applyResolution ();

EndProcedure

&AtServer
Procedure applyResolution ()
	
	PermissionForm.ApplyResolution ( Object );
	Changed = true;
	Appearance.Apply ( ThisObject, "Object.Resolution, Changed" );

EndProcedure
