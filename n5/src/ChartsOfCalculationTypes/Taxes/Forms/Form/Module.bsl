&AtClient
var TableRow;

// *****************************************
// *********** Form events

&AtServer
Procedure OnReadAtServer ( CurrentObject )
	
	readPictures ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readPictures ()
	
	for each row in Object.BaseCalculationTypes do
		setPicture ( row );
	enddo; 
	
EndProcedure 

&AtClientAtServerNoContext
Procedure setPicture ( Row )
	
	type = TypeOf ( Row.CalculationType );
	if ( type = Type ( "ChartOfCalculationTypesRef.Taxes" ) ) then
		picture = 1;
	else
		picture = 0;
	endif; 
	Row.Picture = picture;
	
EndProcedure 

&AtServer
Procedure OnCreateAtServer ( Cancel, StandardProcessing )
	
	filterRates ();
	StandardButtons.Arrange ( ThisObject );
	readAppearance ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

&AtServer
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|Base enable Object.Method <> Enum.Calculations.FixedAmount;
	|Write Warning show empty ( Object.Ref );
	|Method Net enable empty ( Object.Ref );
	|PayrollTaxes enable filled ( Object.Ref );
	|ActualRates show ShowCurrentRates;
	|PayrollTaxes show not ShowCurrentRates;
	|Net show inlist ( Object.Method, Enum.Calculations.FixedAmount, Enum.Calculations.Percent );
	|Expense show not Object.Net;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure filterRates ()
	
	DC.SetFilter ( PayrollTaxes, "Tax", Object.Ref );
	DC.SetFilter ( ActualRates, "Tax", Object.Ref );
	
EndProcedure 

&AtServer
Procedure AfterWriteAtServer ( CurrentObject, WriteParameters )
	
	filterRates ();
	Appearance.Apply ( ThisObject );
	
EndProcedure

// *****************************************
// *********** Group Form

&AtClient
Procedure MethodOnChange ( Item )
	
	PayrollItemForm.MethodOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure DescriptionOnChange ( Item )
	
	PayrollItemForm.DescriptionOnChange ( ThisObject );
	
EndProcedure

&AtClient
Procedure ShowActual ( Command )
	
	toggleRates ();
	
EndProcedure

&AtClient
Procedure toggleRates ()
	
	ShowCurrentRates = not ShowCurrentRates;
	Appearance.Apply ( ThisObject, "ShowCurrentRates" );
	
EndProcedure 

&AtClient
Procedure ShowRecords ( Command )
	
	toggleRates ();

EndProcedure

&AtClient
Procedure NetOnChange ( Item )

	applyNetFlag ();
	
EndProcedure

&AtClient
Procedure applyNetFlag ()
	
	if ( Object.Net ) then
		Object.Expense = undefined;
	endif;
	Appearance.Apply ( ThisObject, "Object.Net" );
	
EndProcedure

// *****************************************
// *********** Table Base

&AtClient
Procedure BaseOnActivateRow ( Item )
	
	TableRow = Item.CurrentData;
	
EndProcedure

&AtClient
Procedure BaseCalculationTypeOnChange ( Item )
	
	setPicture ( TableRow );
	
EndProcedure
