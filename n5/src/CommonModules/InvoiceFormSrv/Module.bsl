
Function GetTaxes ( val TaxGroup, val Date ) export
	
	s = "
	|select Taxes.Tax as Tax, Info.Percent as Percent
	|from Catalog.TaxGroups.Taxes as Taxes
	|	//
	|	// Info
	|	//
	|	left join InformationRegister.TaxItems.SliceLast ( &Date, Tax in ( select distinct Tax from Catalog.TaxGroups.Taxes where Ref = &Ref ) ) as Info
	|	on Info.Tax = Taxes.Tax
	|where Taxes.Ref = &Ref
	|order by Taxes.LineNumber
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", TaxGroup );
	q.SetParameter ( "Date", Date );
	return CollectionsSrv.Serialize ( q.Execute ().Unload () );
	
EndFunction 

Function GetItemData ( val Params ) export
	
	item = Params.Item;
	data = DF.Values ( item, "Package, Package.Capacity as Capacity, VAT, VAT.Rate as Rate, Social" );
	warehouse = Params.Warehouse;
	package = data.Package;
	date = Params.Date;
	price = Goods.Price ( , Params.Date, Params.Prices, item, package, , Params.Organization, Params.Contract, , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Account, SalesCost, Income, VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "Account", accounts.Account );
	data.Insert ( "SalesCost", accounts.SalesCost );
	data.Insert ( "Income", accounts.Income );
	data.Insert ( "VATAccount", accounts.VAT );
	if ( data.Capacity = 0 ) then
		data.Capacity = 1;
	endif;
	p = InvoiceForm.ItemParams ( item, package );
	data.Insert ( "ProducerPrice", ? ( data.Social, Goods.ProducerPrice ( p, date ), 0 ) );
	return data;
	
EndFunction

Function GetServiceData ( val Params ) export
	
	item = Params.Item;
	data = DF.Values ( item, "FullDescription, VAT, VAT.Rate as Rate" );
	warehouse = Params.Warehouse;
	price = Goods.Price ( , Params.Date, Params.Prices, item, , , Params.Organization, Params.Contract, , warehouse, Params.Currency );
	accounts = AccountsMap.Item ( item, Params.Company, warehouse, "Income, VAT" );
	data.Insert ( "Price", price );
	data.Insert ( "Income", accounts.Income );
	data.Insert ( "VATAccount", accounts.VAT );
	return data;
	
EndFunction 
