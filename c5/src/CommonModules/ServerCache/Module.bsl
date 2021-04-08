Function DimExist ( Account, DimName ) export
	
	return Account.DimTypes.Find ( ChartsOfCharacteristicTypes.Dimensions [ DimName ] ) <> undefined;
	
EndFunction

Function DimsCount ( Account ) export
	
	return GeneralAccounts.DimsCount ( Account );
	
EndFunction 

Function AccountData ( Account ) export
	
	return GeneralAccounts.GetData ( Account );
	
EndFunction 

Function Price ( val Date = undefined, val Prices, val Item, val Package = undefined, val Feature = undefined, val Organization, val Warehouse ) export
	
	return Goods.Price ( , Date, Prices, Item, Package, Feature, Organization, , , Warehouse );
	
EndFunction 
