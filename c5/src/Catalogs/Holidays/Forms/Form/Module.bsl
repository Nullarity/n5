// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterByHoliday ();
	setYearByDefault ( ThisObject );
	filterByYear ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Write show empty ( Object.Ref );
	|Holidays enable filled ( Object.Ref )
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure filterByHoliday ()
	
	Holidays.Parameters.SetParameterValue ( "Holidays", Object.Ref );
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setYearByDefault ( Form )
	
	Form.Year = Year ( CurrentDate () );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterByHoliday ();
	Appearance.Apply ( ThisObject, "Object.Ref" );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure YearOnChange ( Item )
	
	filterByYear ();
	
EndProcedure

&AtServer
Procedure filterByYear ()
	
	Holidays.Parameters.SetParameterValue ( "Year", Date ( Year, 1, 1 ) );
	
EndProcedure 

&AtClient
Procedure YearClearing ( Item, StandardProcessing )
	
	StandardProcessing = false;
	setYearByDefault ( ThisObject );
	filterByYear ();
	
EndProcedure

// *****************************************
// *********** Group Holidays

&AtClient
Procedure HolidaysBeforeAddRow ( Item, Cancel, Clone, Parent, Folder )
	
	if ( Clone ) then
		return;
	endif; 
	Cancel = true;
	openNewHoliday ();
	
EndProcedure

&AtClient
Procedure openNewHoliday ()
	
	values = new Structure ( "Reference, Day", Object.Ref, Date ( Year, 1, 1 ) );
	p = new Structure ( "FillingValues", values );
	OpenForm ( "InformationRegister.Holidays.RecordForm", p, Items.Holidays );
	
EndProcedure 
