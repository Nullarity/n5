// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	filterProducts ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure filterProducts ()
	
	DC.ChangeFilter ( DepartmentItems, "Department", Object.Ref, true );
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		CopyingObject = Parameters.CopyingValue;
		fillNew ();
		filterProducts ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|DepartmentItems show Object.Production;
	|DepartmentItems enable Object.Production and filled ( Object.Ref );
	|CopyInfo show filled ( CopyingObject ) and Object.Production;
	|WriteDepartment show
	|empty ( CopyingObject )
	|and empty ( Object.Ref )
	|and Object.Production
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not CopyingObject.IsEmpty () ) then
		return;
	endif; 
	if ( not Object.Owner.IsEmpty () ) then
		return;
	endif; 
	Object.Owner = Logins.Settings ( "Company" ).Company;
	
EndProcedure 

&AtServer
Procedure OnWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	if ( not CopyingObject.IsEmpty () ) then
		copyProducs ( CurrentObject );
	endif;
	
EndProcedure

&AtServer
Procedure copyProducs ( CurrentObject )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.DepartmentItems.CreateRecordSet ();
	r.Filter.Department.Set ( CopyingObject );
	r.Read ();
	products = r.Unload ( , "Item" );
	products.Columns.Add ( "Department" );
	products.FillValues ( CurrentObject.Ref, "Department" );
	r = InformationRegisters.DepartmentItems.CreateRecordSet ();
	r.Load ( products );
	r.Write ( false );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	CopyingObject = undefined;
	filterProducts ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	Appearance.Apply ( ThisObject, "CopyingObject" );

EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure ProductionOnChange ( Item )
	
	Appearance.Apply ( ThisObject, "Object.Production" );
	
EndProcedure
