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
	
	if ( Object.Ref.IsEmpty () ) then
		raise Output.InteractiveCreationForbidden ();
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
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

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
	
	PermissionForm.SendChangesResponse ( Object );
	
EndProcedure

&AtClient
Procedure AfterWrite ( WriteParameters )

	Notify ( Enum.MessageChangesPermissionIsSaved (), ? ( Object.Document = undefined, Object.Day, Object.Document ) );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure DateOnChange ( Item )

	updateChangesPermission ();
	
EndProcedure

&AtClient
Procedure ResolutionOnChange ( Item )
	
	applyResolution ();

EndProcedure

&AtServer
Procedure applyResolution ()
	
	PermissionForm.ApplyResolution ( Object );
	Appearance.Apply ( ThisObject, "Object.Resolution" );

EndProcedure