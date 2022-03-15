// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Constraints.ShowAccess ( ThisObject );
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		DocumentForm.Init ( Object );
		fillNew ();
		Constraints.ShowAccess ( ThisObject );
	endif; 
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Department enable Object.Role = Enum.Roles.DepartmentHead and empty ( Object.Ссылка );
	|Information Create show filled ( Object.Ссылка );
	|Apply show empty ( Object.Ссылка );
	|Company Action User Role Memo enable empty ( Object.Ссылка )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	settings = Logins.Settings ( "Company" );
	Object.Company = settings.Company;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WritingParameters )
	
	applyChanges ();
	
EndProcedure

&AtServer
Procedure applyChanges ()
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.BPRouter.CreateRecordManager ();
	r.User = Object.User;
	r.Role = Object.Role;
	r.Department = Object.Department;
	r.Activity = true;
	if ( Object.Action = Enums.AssignRoles.Assign ) then
		r.Write ();
	else
		r.Delete ();
	endif; 
	SetPrivilegedMode ( false );
	
EndProcedure 

&AtClient
Procedure AfterWrite ( WritingParameters )
	
	NotifyChanged ( Type ( "InformationRegisterRecordKey.BPRouter" ) );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure Create ( Command )
	
	callback = new NotifyDescription ( "CloseForm", ThisObject );
	OpenForm ( "Document.Roles.ObjectForm", new Structure ( "CopyingValue", Object.Ref ), , , , , callback );
	
EndProcedure

&AtClient
Procedure CloseForm ( Result, Params ) export
	
	Close ();
	
EndProcedure 

&AtClient
Procedure RoleOnChange ( Item )
	
	applyRole ();
	
EndProcedure

&AtServer
Procedure applyRole ()
	
	if ( Object.Role <> Enums.Roles.DepartmentHead ) then
		Object.Department = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Role" );
	
EndProcedure
