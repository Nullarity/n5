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
	
	Base = Parameters.Base;
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
	|Organization show filled ( Object.Organization );
	|Class show empty ( Object.Document );
	|Document show filled ( Object.Document );
	|Responsible show filled ( Object.Resolution );
	|FormOK show Changed;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

#region Filling

&AtServer
Procedure fill ()
	
	if ( TypeOf ( Base ) = Type ( "Date" ) ) then
		Object.Day = Base;
		Object.Company = Logins.Settings ( "Company" ).Company;
	else
		Object.Document = Base;
		data = documentData ();
		FillPropertyValues ( Object, data );
		Object.Day = BegOfDay ( data.Day );
	endif;
	Object.Date = CurrentSessionDate ();
	Object.Creator = SessionParameters.User;
	Object.DeletionMark = false;
	Object.Responsible = undefined;
	Object.Resolution = undefined;
	Object.Expired = undefined;
	Object.Class = MetadataRef.Get ( Parameters.Document.Metadata ().FullName () );
	Changed = true;

EndProcedure

&AtServer
Function documentData ()
	
	fields = new Array ();
	fields.Add ( "Company" );
	fields.Add ( "Date as Day" );
	meta = Metadata.FindByType ( TypeOf ( Parameters.Document ) ).Attributes;
	if ( meta.Find ( "Customer" ) <> undefined ) then
		fields.Add ( "Customer as Organization" );
	elsif ( meta.Find ( "Vendor" ) ) then
		fields.Add ( "Vendor as Organization" );
	endif;
	return DF.Values ( Base, StrConcat ( fields, "," ) );
	
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
		PermissionForm.SendChangesResponse ( Object );
	endif;
	
EndProcedure

&AtServer
Procedure sendRequest ()
	
	params = new Array ();
	params.Add ( Object.Ref );
	Jobs.Run ( "ChangesPermissionMailing.Send", params, , , TesterCache.Testing () );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )

	Notify ( Enum.MessageChangesPermissionIsSaved (), ? ( Object.Document = undefined, Object.Day, Object.Document ) );

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
