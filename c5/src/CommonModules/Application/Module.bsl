Function Accuracy () export
	
	return "NFD=" + Format ( Constants.Accuracy.Get (), "NZ=" );
	
EndFunction 

Function Currency () export
	
	return Constants.Currency.Get ();
	
EndFunction 

Function Schedule () export
	
	return Constants.Schedule.Get ();
	
EndFunction 

Function Unit () export
	
	return Constants.Unit.Get ();
	
EndFunction 

Function Company () export
	
	return Constants.Company.Get ();
	
EndFunction 

Function Country () export
	
	return Constants.Country.Get ();
	
EndFunction 

Function Prefix () export
	
	return Constants.Prefix.Get ();
	
EndFunction 

Function AccountsName () export
	
	return Constants.AccountsPresentation.Get () = Enums.Presentation.Name;
	
EndFunction 

Function Discounts () export
	
	return Constants.Discounts.Get ();
	
EndFunction 

Function ItemsVAT () export
	
	return Constants.ItemsVAT.Get ();
	
EndFunction 

Function ItemsCost () export
	
	return Constants.ItemsCost.Get ();
	
EndFunction 

Function NewItems () export
	
	return Constants.NewItems.Get ();
	
EndFunction 
