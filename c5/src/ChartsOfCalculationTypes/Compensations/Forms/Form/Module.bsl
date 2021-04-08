&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	Appearance.Apply ( ThisObject );
	fillTaxes ();
	
EndProcedure

&AtServer
Procedure fillTaxes ()
	
	s = "
	|select Taxes.Ref as Tax, case when Base.Ref is null then false else true end as Use
	|from ChartOfCalculationTypes.Taxes as Taxes
	|	//
	|	// Base
	|	//
	|	left join ChartOfCalculationTypes.Taxes.BaseCalculationTypes as Base
	|	on Base.Ref = Taxes.Ref
	|	and Base.CalculationType = &Ref
	|where not Taxes.DeletionMark
	|order by Taxes.Code
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	Taxes.Load ( q.Execute ().Unload () );

EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	if ( Object.Ref.IsEmpty () ) then
		fillNew ();
		fillTaxes ();
	endif; 
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Base enable inlist ( Object.Method, Enum.Calculations.Percent, Enum.Calculations.Vacation, Enum.Calculations.SickDays, Enum.Calculations.SickProduction, Enum.Calculations.SickOnlySocial, Enum.Calculations.SickDaysChild, Enum.Calculations.ExtendedVacation );
	|HourlyRate show Object.Method = Enum.Calculations.MonthlyRate;
	|Insurance show inlist ( Object.Method, Enum.Calculations.SickDays, Enum.Calculations.SickProduction, Enum.Calculations.SickOnlySocial, Enum.Calculations.SickDaysChild );
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( not Object.Method.IsEmpty () ) then
		PayrollItemForm.SetDescription ( Object );
	endif; 
	p = new Structure ( "Parameter", ChartsOfCharacteristicTypes.Settings.PayrollAccount );
	Object.Account = InformationRegisters.Settings.GetLast ( , p ).Value;
	
EndProcedure 

&AtServer
Procedure BeforeWriteAtServer ( Cancel, CurrentObject, WriteParameters )
	
	CurrentObject.AdditionalProperties.Insert ( "Taxes", Taxes );
	
EndProcedure

// *****************************************
// *********** Group Main

&AtClient
Procedure MethodOnChange ( Item )
	
	PayrollItemForm.MethodOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DescriptionOnChange ( Item )
	
	PayrollItemForm.DescriptionOnChange ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Table Taxes

&AtClient
Procedure MarkAll ( Command )
	
	markTaxes ( true );
	
EndProcedure

&AtClient
Procedure markTaxes ( Flag )
	
	for each row in Taxes do
		row.Use = Flag;
		row.Dirty = true;
	enddo; 
	
EndProcedure 

&AtClient
Procedure UnmarkAll ( Command )
	
	markTaxes ( false );
	
EndProcedure

&AtClient
Procedure TaxesOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure TaxesSelection ( Item, SelectedRow, Field, StandardProcessing )
	
	ShowValue ( , TableRow.Tax );
	
EndProcedure

&AtClient
Procedure TaxesBeforeAddRow ( Item, Cancel, Clone, Parent, Folder, Parameter )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure TaxesBeforeDeleteRow ( Item, Cancel )
	
	Cancel = true;
	
EndProcedure

&AtClient
Procedure TaxesUseOnChange ( Item )
	
	TableRow.Dirty = true;
	
EndProcedure
