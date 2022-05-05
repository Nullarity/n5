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
Procedure readAppearance ()

	rules = new Array ();
	rules.Add ( "
	|RoundMethod RoundToNextPart enable Object.Pricing <> Enum.Pricing.Base;
	|BasePrices Detail enable not inlist ( Object.Pricing, Enum.Pricing.Base, Enum.Pricing.Cost );
	|Percent enable Object.Pricing = Enum.Pricing.Percent;
	|" );
	Appearance.Read ( ThisObject, rules );

EndProcedure

&AtServer
Procedure fillNew ()
	
	if ( not Parameters.CopyingValue.IsEmpty () ) then
		return;
	endif; 
	if ( Object.Owner.IsEmpty () ) then
		settings = Logins.Settings ( "Company" );
		Object.Owner = settings.Company;
	endif; 
	Object.Currency = Application.Currency ();
	
EndProcedure 

// *****************************************
// *********** Group Form

&AtClient
Procedure CalculationMethodOnChange ( Item )
	
	resetFieldsByCalculationMethod ();
	Appearance.Apply ( ThisObject, "Object.Pricing" );
	
EndProcedure

&AtServer
Procedure resetFieldsByCalculationMethod ()
	
	if ( Object.Pricing = Enums.Pricing.Base ) then
		Object.BasePrices = undefined;
		Object.RoundMethod = undefined;
		Object.RoundToNextPart = false;
	elsif ( Object.Pricing = Enums.Pricing.Cost ) then
		Object.BasePrices = undefined;
	elsif ( Object.Pricing = Enums.Pricing.Percent ) then
		Object.Detail = Enums.PriceDetails.Item;
	endif;
	if ( Object.Pricing <> Enums.Pricing.Percent ) then
		Object.Percent = 0;
	endif;
	
EndProcedure 
