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
	|BasePrices Detail enable not inlist ( Object.Pricing,
	|	Enum.Pricing.Base, Enum.Pricing.Cost, Enum.Pricing.Purchase );
	|Percent enable Object.Pricing = Enum.Pricing.Percent;
	|Currency enable Object.Pricing <> Enum.Pricing.Cost;
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
Procedure PricingOnChange ( Item )
	
	applyPricing ();
	
EndProcedure

&AtServer
Procedure applyPricing ()
	
	pricing = Object.Pricing;
	if ( pricing = Enums.Pricing.Base ) then
		Object.BasePrices = undefined;
		Object.RoundMethod = undefined;
		Object.RoundToNextPart = false;
	elsif ( pricing = Enums.Pricing.Cost ) then
		Object.BasePrices = undefined;
		Object.Currency = Application.Currency ();
	elsif ( pricing = Enums.Pricing.Purchase ) then
		Object.BasePrices = undefined;
	elsif ( pricing = Enums.Pricing.Percent ) then
		Object.Detail = Enums.PriceDetails.Item;
	endif;
	if ( pricing <> Enums.Pricing.Percent ) then
		Object.Percent = 0;
	endif;
	Appearance.Apply ( ThisObject, "Object.Pricing" );
	
EndProcedure 
