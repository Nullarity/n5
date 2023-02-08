Function GetData ( val Item, val Company, val Warehouse ) export
	
	result = new Structure ( "VAT, Rate, IncomeAccount, VATAccount" );
	data = DF.Values ( Item, "VAT, VAT.Rate as Rate" );
	accounts = AccountsMap.Item ( Item, Company, Warehouse, "Income, VAT" );
	result.VAT = data.VAT;
	result.Rate = data.Rate;
	result.IncomeAccount = accounts.Income;
	result.VATAccount = accounts.VAT;
	return result;
	
EndFunction