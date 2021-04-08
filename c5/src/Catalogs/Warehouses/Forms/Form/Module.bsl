// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
	endif;
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
		
EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif;
	if ( Object.Owner.IsEmpty () ) then
		Object.Owner = Logins.Settings ( "Company" ).Company;
	endif; 
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Address Contact enable filled ( Object.Ref );
	|Write show empty ( Object.Ref );
	|Responsible show inlist ( Object.Class, Enum.WarehouseTypes.Salesman, Enum.WarehouseTypes.Car );
	|Department show Object.Production
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	Appearance.Apply ( ThisObject );

EndProcedure

// *****************************************
// *********** Group Main

&AtClient
Procedure ClassOnChange ( Item )
	
	applyClass ();
	
EndProcedure

&AtServer
Procedure applyClass ()
	
	class = Object.Class;
	if ( class <> Enums.WarehouseTypes.Salesman
		and class <> Enums.WarehouseTypes.Car ) then
		Object.Responsible = undefined;
	endif; 
	Appearance.Apply ( ThisObject, "Object.Class" );
	
EndProcedure 

&AtClient
Procedure ResponsibleOnChange ( Item )
	
	setDescription ();
	
EndProcedure

&AtClient
Procedure setDescription ()
	
	Object.Description = Object.Responsible;
	
EndProcedure 

&AtClient
Procedure ProductionOnChange ( Item )
	
	applyProduction ();
	
EndProcedure

&AtClient
Procedure applyProduction ()
	
	if ( not Object.Production ) then
		Object.Department = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Production" );
	
EndProcedure