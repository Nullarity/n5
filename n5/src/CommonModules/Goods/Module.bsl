
Function PriceParams () export
	
	p = new Structure ();
	p.Insert ( "Date" );
	p.Insert ( "Prices" );
	p.Insert ( "Item" );
	p.Insert ( "Package" );
	p.Insert ( "Feature" );
	p.Insert ( "Organization" );
	p.Insert ( "Contract" );
	p.Insert ( "VendorContract", false );
	p.Insert ( "Warehouse" );
	p.Insert ( "Currency" );
	return p;
	
EndFunction 

Function GetTax ( val TaxGroup, val Date ) export
	
	s = "
	|select sum ( TaxItems.Percent ) as Percent
	|from InformationRegister.TaxItems.SliceLast ( &Date, Tax in ( select distinct Tax from Catalog.TaxGroups.Taxes where Ref = &Ref ) ) as TaxItems
	|where TaxItems.Percent <> 0	
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", TaxGroup );
	q.SetParameter ( "Date", Date );
	percent = q.Execute ().Unload () [ 0 ].Percent;
	return ? ( percent = null, 0, percent );
	
EndFunction 

Function Price (
	Cache = undefined,
	val Date,
	val Prices,
	val Item,
	val Package = undefined,
	val Feature = undefined,
	val Organization = undefined,
	val Contract = undefined,
	val VendorContract = false,
	val Warehouse = undefined,
	val Currency = undefined ) export
	
	p = Goods.PriceParams ();
	p.Date = Date;
	p.Prices = Prices;
	p.Item = Item;
	if ( ValueIsFilled ( Package ) ) then
		p.Package = Package;
	endif;
	if ( ValueIsFilled ( Feature ) ) then
		p.Feature = Feature;
	endif;
	if ( ValueIsFilled ( Organization ) ) then
		p.Organization = Organization;
	endif;
	if ( ValueIsFilled ( Contract ) ) then
		p.Contract = Contract;
	endif;
	if ( ValueIsFilled ( VendorContract ) ) then
		p.VendorContract = VendorContract;
	endif;
	if ( ValueIsFilled ( Warehouse ) ) then
		p.Warehouse = Warehouse;
	endif;
	if ( ValueIsFilled ( Currency ) ) then
		p.Currency = Currency;
	endif;
	return Goods.GetPrice ( p, Cache );
	
EndFunction 

Function GetPrice ( val Params, Cache = undefined ) export
	
	return calcPrice ( Cache, Params, Params.Prices );
	
EndFunction

Function calcPrice ( Cache, Params, Prices )
	
	contractDefined = Params.Contract <> undefined;
	if ( not contractDefined
		and not ValueIsFilled ( Prices ) ) then
		return 0;
	endif; 
	cachedPrice = GetCachedPrice ( Cache, Params );
	if ( cachedPrice.Price <> undefined ) then
		return cachedPrice.Price;
	endif; 
	priceOrPercent = 0;
	if ( contractDefined ) then
		priceOrPercent = getContractPrice ( Cache, Params, Prices );
	elsif ( Prices.Pricing = Enums.Pricing.Group ) then
		priceOrPercent = getPriceForPriceGroups ( Cache, Params, Prices );
	elsif ( Prices.Pricing = Enums.Pricing.Percent ) then
		priceOrPercent = getPriceForPercent ( Cache, Params, Prices );
	elsif ( Prices.Pricing = Enums.Pricing.ItemPercent ) then
		priceOrPercent = getPriceItemPercent ( Cache, Params, Prices );
	elsif ( Prices.Pricing = Enums.Pricing.Base ) then
		priceOrPercent = getPriceForBase ( Cache, Params, Prices );
	elsif ( Prices.Pricing = Enums.Pricing.Cost ) then
		priceOrPercent = getCost ( Cache, Params, Prices );
	endif; 
	if ( cachedPrice.CacheEnabled ) then
		cachedPrice.CashItem.Price = priceOrPercent;
	endif; 
	return priceOrPercent;
	
EndFunction

Function getContractPrice ( Cache, Params, Prices )
	
	price = fetchContractPrice ( Params );
	if ( price = 0 ) then
		Params.Contract = undefined;
		return calcPrice ( Cache, Params, Prices );
	else
		convertToCurrency ( Params, price, Prices );
		return price;
	endif; 
	
EndFunction 

Function fetchContractPrice ( Params )
	
	if ( Params.VendorContract ) then
		prefix = "Vendor";
		prices = "VendorPrices";
	else
		prefix = "";
		prices = "CustomerPrices";
	endif; 
	price = "Prices.Price * ( isnull ( Packages.Capacity, 1 ) / case when Prices.Package = value ( Catalog.Packages.EmptyRef ) then 1 else Package.Capacity end ) as Price";
	packages = "left join Catalog.Packages as Packages on Packages.Ref = &Package";
	s = "
	|select top 1 " + price + "
	|from (
	|	select case when Prices.Package = &Package then 1 else 0 end as _1,
	|		case when Prices.Feature = &Feature then 10 else 0 end as _2,
	|		Prices.Price as Price, Prices.Feature as Feature, Prices.Package as Package
	|	from (
	|		select Items.Item as Item, Items.Feature as Feature, Items.Package as Package, Items.Price as Price
	|		from Catalog.Contracts." + prefix + "Items as Items
	|		where Items.Ref = &Ref
	|		and Items.Item = &Item
	|		and Items.Ref." + prices + " in ( value ( Catalog.Prices.EmptyRef ), &Prices )
	|		union all
	|		select Services.Item, Services.Feature, value ( Catalog.Packages.EmptyRef ), Services.Price
	|		from Catalog.Contracts." + prefix + "Services as Services
	|		where Services.Ref = &Ref
	|		and Services.Item = &Item
	|		and Services.Ref." + prices + " in ( value ( Catalog.Prices.EmptyRef ), &Prices )
	|	) as Prices
	|) as Prices
	|" + packages + "
	|where Prices.Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
	|and Prices.Feature in ( &Feature, value ( Catalog.Features.EmptyRef ) )
	|order by ( Prices._1 + Prices._2 ) desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Params.Contract );
	q.SetParameter ( "Item", Params.Item );
	q.SetParameter ( "Feature", Params.Feature );
	q.SetParameter ( "Package", Params.Package );
	q.SetParameter ( "Prices", Params.Prices );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Price );

EndFunction 

Function GetCachedPrice ( Cache, Params ) export
	
	resultStruct = new Structure ( "CacheEnabled, Price, CashItem", false );
	if ( Cache <> undefined ) then
		cachedArray = Cache [ Params.Item ];
		if ( cachedArray <> undefined ) then
			for each cachedPrice in cachedArray do
				if ( cachedPrice.Prices = Params.Prices
					and cachedPrice.Date = Params.Date
					and cachedPrice.Package = Params.Package
					and cachedPrice.Feature = Params.Feature
					and cachedPrice.Organization = Params.Organization
					and cachedPrice.Contract = Params.Contract
					and cachedPrice.VendorContract = Params.VendorContract
					and cachedPrice.Warehouse = Params.Warehouse
					and cachedPrice.Currency = Params.Currency ) then
					resultStruct.Price = cachedPrice.Price;
					return resultStruct;
				endif; 
			enddo; 
		else
			Cache [ Params.Item ] = new Array ();
		endif; 
		p = new Structure ( "Date, Prices, Package, Feature, Organization, Contract, VendorContract, Warehouse, Price, Currency",
		Params.Date, Params.Prices, Params.Package, Params.Feature, Params.Organization, Params.Contract, Params.VendorContract, Params.Warehouse, undefined, Params.Currency );
		Cache [ Params.Item ].Add ( p );
		resultStruct.CashItem = Cache [ Params.Item ] [ Cache [ Params.Item ].UBound () ];
		resultStruct.CacheEnabled = true;
	endif; 
	return resultStruct;
	
EndFunction

Function getPriceForPriceGroups ( Cache, Params, Prices )

	basePrice = calcPrice ( Cache, Params, Prices.BasePrices );
	percent = getPercentForPriceGroup ( Params, Prices );
	price = basePrice + ( basePrice / 100 * percent );
	finalizePrice ( price, Params, Prices );
	return price;
	
EndFunction

Function getPercentForPriceGroup ( Params, Prices )

	s = getPercentForPriceGroupSql ( Params, Prices );
	q = new Query ( s );
	q.SetParameter ( "Date", Params.Date );
	q.SetParameter ( "Prices", Prices );
	q.SetParameter ( "PriceGroup", DF.Pick ( Params.Item, "PriceGroup" ) );
	q.SetParameter ( "Organization", Params.Organization );
	q.SetParameter ( "Warehouse", Params.Warehouse );
	resultTable = q.Execute ().Unload ();
	return ? ( resultTable.Count () > 0, resultTable [ 0 ].Percent, 0 );
	
EndFunction

Function getPercentForPriceGroupSql ( Params, Prices )

	if ( Prices.Detail = Enums.PriceDetails.Item ) then
		s = "
		|select LastPrices.Percent as Percent
		|from InformationRegister.PriceGroups.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|	and Prices = &Prices and PriceGroup = &PriceGroup
		|	and Organization = value ( Catalog.Organizations.EmptyRef )
		|	and Warehouse = value ( Catalog.Warehouses.EmptyRef ) ) as LastPrices
		|where LastPrices.Percent <> 0
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndWarehouseAndOrganization ) then
		s = "
		|select top 1 ( LastPrices._1 + LastPrices._2 ) as Priority, LastPrices.Percent as Percent
		|from (
		|	select case when Warehouse = &Warehouse then 1 else 0 end as _1,
		|			case when Organization = &Organization then 10 else 0 end as _2,
		|			Percent as Percent
		|	from InformationRegister.PriceGroups.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices and PriceGroup = &PriceGroup
		|		and Organization in ( &Organization, value ( Catalog.Organizations.EmptyRef ) )
		|		and Warehouse in ( &Warehouse, value ( Catalog.Warehouses.EmptyRef ) ) ) ) as LastPrices
		|where LastPrices.Percent <> 0
		|order by Priority desc
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndOrganization ) then
		s = "
		|select top 1 LastPrices._1 as Priority, LastPrices.Percent as Percent
		|from (
		|	select case when Organization = &Organization then 1 else 0 end as _1, Percent as Percent
		|	from InformationRegister.PriceGroups.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices
		|		and PriceGroup = &PriceGroup
		|		and Warehouse = value ( Catalog.Warehouses.EmptyRef )
		|		and Organization in ( &Organization, value ( Catalog.Organizations.EmptyRef ) ) ) ) as LastPrices
		|where LastPrices.Percent <> 0
		|order by Priority desc
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndWarehouse ) then
		s = "
		|select top 1 LastPrices._1 as Priority, LastPrices.Percent as Percent
		|from (
		|	select case when Warehouse = &Warehouse then 1 else 0 end as _1, Percent as Percent
		|	from InformationRegister.PriceGroups.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices
		|		and PriceGroup = &PriceGroup
		|		and Organization = value ( Catalog.Organizations.EmptyRef )
		|		and Warehouse in ( &Warehouse, value ( Catalog.Warehouses.EmptyRef ) ) ) ) as LastPrices
		|where LastPrices.Percent <> 0
		|order by Priority desc
		|";
	endif; 
	return s;
	
EndFunction

Procedure finalizePrice ( Price, Params, Prices )
	
	convertToCurrency ( Params, Price, Prices );
	roundPrice ( Price, Prices );
	
EndProcedure 

Procedure convertToCurrency ( Params, Price, Prices )
	
	currency = Params.Currency;
	if ( currency = undefined ) then
		return;
	endif;
	contract = Params.Contract;
	originalCurrency = ? ( contract = undefined, Prices.Currency, DF.Pick ( contract, "Currency" ) );
	if ( currency = originalCurrency ) then
		return;
	endif; 
	date = Params.Date;
	rates = CurrenciesSrv.Get ( currency, date );
	originalRates = CurrenciesSrv.Get ( originalCurrency, date );
	localizedPrice = Price * originalRates.Rate / originalRates.Factor;
	Price = localizedPrice / rates.Rate * rates.Factor;
	
EndProcedure 

Procedure roundPrice ( Price, Prices )
	
	if ( Prices.Pricing = Enums.Pricing.Base ) then
		return;
	endif; 
	factor = getRoundMethodFactor ( Prices );
	intervalCount = Price / factor;
	wholeIntervalCount = Int ( intervalCount );
	if ( intervalCount = wholeIntervalCount ) then
		return;
	else		
		if ( Prices.RoundToNextPart ) then
			Price = factor * ( wholeIntervalCount + 1 );			
		else
			Price = factor * Round ( intervalCount, 0, RoundMode.Round15as20 );
		endif;
	endif;
	
EndProcedure 

Function getRoundMethodFactor ( Prices )
	
	method = Prices.RoundMethod;
	if ( method = Enums.Rounding.Round0_01 ) then
		return 0.01;
	elsif ( method = Enums.Rounding.Round0_05 ) then
		return 0.05;
	elsif ( method = Enums.Rounding.Round0_1 ) then
		return 0.1;
	elsif ( method = Enums.Rounding.Round0_5 ) then
		return 0.5;
	elsif ( method = Enums.Rounding.Round1 ) then
		return 1;
	elsif ( method = Enums.Rounding.Round5 ) then
		return 5;
	elsif ( method = Enums.Rounding.Round10 ) then
		return 10;
	elsif ( method = Enums.Rounding.Round50 ) then
		return 50;
	elsif ( method = Enums.Rounding.Round100 ) then
		return 100;
	endif; 
	
EndFunction 

Function getPriceForPercent ( Cache, Params, Prices )
	
	basePrice = calcPrice ( Cache, Params, Prices.BasePrices );
	price = basePrice + ( basePrice / 100 * Prices.Percent );
	finalizePrice ( price, Params, Prices );
	return price;
	
EndFunction

Function getPriceItemPercent ( Cache, Params, Prices )
	
	basePrice = calcPrice ( Cache, Params, Prices.BasePrices );
	percent = getPriceOrPercentFromPrices ( Params, Prices );
	price = basePrice + ( basePrice / 100 * percent );
	finalizePrice ( price, Params, Prices );
	return price;
	
EndFunction

Function getPriceOrPercentFromPrices ( Params, Prices )

	s = getPriceOrPercentSql ( Params, Prices );
	q = new Query ( s );
	q.SetParameter ( "Date", Params.Date );
	q.SetParameter ( "Prices", Prices );
	q.SetParameter ( "Item", Params.Item );
	q.SetParameter ( "Package", ? ( Params.Package = undefined, Catalogs.Packages.EmptyRef (), Params.Package ) );
	q.SetParameter ( "Feature", Params.Feature );
	q.SetParameter ( "Organization", Params.Organization );
	q.SetParameter ( "Warehouse", Params.Warehouse );
	resultTable = q.Execute ().Unload ();
	return ? ( resultTable.Count () > 0, resultTable [ 0 ].PriceOrPercent, 0 );
	
EndFunction

Function getPriceOrPercentSql ( Params, Prices )
	
	if ( Prices.Pricing = Enums.Pricing.Base ) then
		priceField = "Prices.PriceOrPercent * ( isnull ( Packages.Capacity, 1 ) / case when Prices.Package = value ( Catalog.Packages.EmptyRef ) then 1 else Package.Capacity end ) as PriceOrPercent";
		joinItemPackages = "left join Catalog.Packages as Packages on Packages.Ref = &Package";
	else
		priceField = "Prices.PriceOrPercent as PriceOrPercent";
		joinItemPackages = "";
	endif; 
	if ( Prices.Detail = Enums.PriceDetails.Item ) then
		s = "
		|select top 1 ( Prices._1 + Prices._2 ) as Priority, " + priceField + "
		|from (
		|	select case when Package = &Package then 1 else 0 end as _1,
		|			case when Feature = &Feature then 10 else 0 end as _2,
		|			PriceOrPercent as PriceOrPercent,
		|			Package as Package
		|	from InformationRegister.Prices.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices
		|		and Item = &Item
		|		and Organization = value ( Catalog.Organizations.EmptyRef )
		|		and Warehouse = value ( Catalog.Warehouses.EmptyRef )
		|		and Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
		|		and Feature in ( &Feature, value ( Catalog.Features.EmptyRef ) ) ) ) as Prices
		|" + joinItemPackages + "
		|where Prices.PriceOrPercent <> 0
		|order by ( Prices._1 + Prices._2 ) desc
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndWarehouseAndOrganization ) then
		s = "
		|select top 1 ( Prices._1 + Prices._2 + Prices._3 + Prices._4 ) as Priority, " + priceField + "
		|from (
		|	select case when Package = &Package then 1 else 0 end as _1,
		|			case when Feature = &Feature then 10 else 0 end as _2,
		|			case when Warehouse = &Warehouse then 100 else 0 end as _3,
		|			case when Organization = &Organization then 1000 else 0 end as _4,
		|			PriceOrPercent as PriceOrPercent,
		|			Package as Package
		|	from InformationRegister.Prices.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices
		|		and Item = &Item
		|		and Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
		|		and Feature in ( &Feature, value ( Catalog.Features.EmptyRef ) )
		|		and Organization in ( &Organization, value ( Catalog.Organizations.EmptyRef ) )
		|		and Warehouse in ( &Warehouse, value ( Catalog.Warehouses.EmptyRef ) ) ) ) as Prices
		|" + joinItemPackages + "
		|where Prices.PriceOrPercent <> 0
		|order by Priority desc
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndOrganization ) then
		s = "
		|select top 1 ( Prices._1 + Prices._2 + Prices._3 ) as Priority, " + priceField + "
		|from (
		|	select case when Package = &Package then 1 else 0 end as _1,
		|			case when Feature = &Feature then 10 else 0 end as _2,
		|			case when Organization = &Organization then 100 else 0 end as _3,
		|			PriceOrPercent as PriceOrPercent,
		|			Package as Package
		|	from InformationRegister.Prices.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices and Item = &Item
		|		and Warehouse = value ( Catalog.Warehouses.EmptyRef )
		|		and Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
		|		and Feature in ( &Feature, value ( Catalog.Features.EmptyRef ) )
		|		and Organization in ( &Organization, value ( Catalog.Organizations.EmptyRef ) ) ) ) as Prices
		|" + joinItemPackages + "
		|where Prices.PriceOrPercent <> 0
		|order by Priority desc
		|";
	elsif ( Prices.Detail = Enums.PriceDetails.ItemAndWarehouse ) then
		s = "
		|select top 1 ( Prices._1 + Prices._2 + Prices._3 ) as Priority, " + priceField + "
		|from (
		|	select case when Package = &Package then 1 else 0 end as _1,
		|			case when Feature = &Feature then 10 else 0 end as _2,
		|			case when Warehouse = &Warehouse then 100 else 0 end as _3,
		|			PriceOrPercent as PriceOrPercent,
		|			Package as Package
		|	from InformationRegister.Prices.SliceLast ( &Date, ( &Date <= DateTo or DateTo = datetime ( 1, 1, 1 ) )
		|		and Prices = &Prices
		|		and Item = &Item
		|		and Organization = value ( Catalog.Organizations.EmptyRef )
		|		and Package in ( &Package, value ( Catalog.Packages.EmptyRef ) )
		|		and Feature in ( &Feature, value ( Catalog.Features.EmptyRef ) )
		|		and Warehouse in ( &Warehouse, value ( Catalog.Warehouses.EmptyRef ) ) ) ) as Prices
		|" + joinItemPackages + "
		|where Prices.PriceOrPercent <> 0
		|order by Priority desc
		|";
	endif; 
	return s;
	
EndFunction 

Function getPriceForBase ( Cache, Params, Prices )
	
	price = getPriceOrPercentFromPrices ( Params, Prices );
	finalizePrice ( price, Params, Prices );
	return price;
	
EndFunction 

Function getCost ( Cache, Params, Prices )
	
	price = getItemCost ( Params, Prices );
	finalizePrice ( price, Params, Prices );
	return price;
	
EndFunction 

Function getItemCost ( Params, Prices )

	q = new Query ();
	s = "
	|select ItemKey
	|from InformationRegister.ItemDetails as Details
	|where Details.Item = &Item";
	if ( Params.Feature <> undefined ) then
		s = s + "
		|and Details.Feature = &Feature";
		q.SetParameter ( "Feature", Params.Feature );
	endif;
	if ( Params.Warehouse <> undefined ) then
		s = s + "
		|and Details.Warehouse = &Warehouse";
		q.SetParameter ( "Warehouse", Params.Warehouse );
	endif;
	if ( Params.Package <> undefined ) then
		s = s + "
		|and Details.Package = &Package
		|union
		|" + s + "
		|and Details.Package = value ( Catalog.Packages.EmptyRef )";
		q.SetParameter ( "Package", Params.Package );
	endif;
	s = "
	|select Cost.AmountBalance / case Cost.QuantityBalance when 0 then 1 else Cost.QuantityBalance end as Price
	|from AccumulationRegister.Cost.Balance ( &Date, ItemKey in ( " + s + " ) ) as Cost
	|";
	q.Text = s;
	q.SetParameter ( "Date", Periods.GetOperationalDate ( Params.Date ) );
	q.SetParameter ( "Item", Params.Item );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Price );
	
EndFunction

Function GetCustomerPrices ( Contract, Warehouse, Cache = undefined ) export
	
	prices = getPrices ( Contract, "CustomerPrices", Cache );
	if ( not ValueIsFilled ( prices ) ) then
		prices = getPrices ( Warehouse, "Prices", Cache );
	endif; 
	return prices;
	
EndFunction 

Function getPrices ( ContractOrWarehouse, Field, Cache )
	
	prices = undefined;
	if ( Cache <> undefined ) then
		prices = Cache [ ContractOrWarehouse ];
	endif;
	if ( prices = undefined ) then
		prices = DF.Pick ( ContractOrWarehouse, Field );
		if ( Cache <> undefined ) then
			Cache [ ContractOrWarehouse ] = prices;
		endif; 
	endif; 
	return prices;
	
EndFunction 

Function GetVendorPrices ( Contract, Cache = undefined ) export
	
	return getPrices ( Contract, "VendorPrices", Cache );
	
EndFunction 

Function GetCostPrices ( Company, Cache = undefined ) export
	
	return getPrices ( Company, "CostPrices", Cache );
	
EndFunction 

Function ProducerPrice ( val ItemParams, val Date ) export 

	s = "
	|select top 1 case when Item.Social then Prices.Price else 0 end as Price
	|from InformationRegister.ProducerPrices.SliceLast ( &Date, Item = &Item
	|	and case when Item.CountPackages then Package = &Package else true end
	|	and Feature = &Feature ) as Prices
	|order by Prices.Period desc
	|";
	q = new Query ( s );
	q.SetParameter ( "Item", ItemParams.Item );
	package = ItemParams.Package;
	q.SetParameter ( "Package", ? ( package = undefined, Catalogs.Packages.EmptyRef (), package ) );
	feature = ItemParams.Feature;
	q.SetParameter ( "Feature", ? ( feature = undefined, Catalogs.Features.EmptyRef (), feature ) );
	q.SetParameter ( "Date", Date );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, 0, table [ 0 ].Price );

EndFunction

Function NewEAN13 () export
	
	next = Min ( getMax () + 1, 99999999 );
	return convertToCode ( next );

EndFunction

Function getMax ( UnitPrefix = "0", InternalPrefix = "00" )

	s = "
	|select max ( substring ( Barcodes.Barcode, 5, 8 ) ) as Code
	|from InformationRegister.Barcodes as Barcodes
	|where Barcodes.Barcode like ""2" + UnitPrefix + InternalPrefix + "_________""
	|";
	q = new Query ( s );
	selection = q.Execute ().Select ();
	selection.Next ();
	numberType = new TypeDescription ( "Number" );
	result = numberType.AdjustValue ( selection.Code );
	return result;

EndFunction

Function convertToCode ( Next, UnitPrefix = "0", InternalPrefix = "00" )

	barcode = "2" + UnitPrefix + InternalPrefix + Format ( Next, "ND=8; NLZ=; NG=");
	barcode = barcode + symbol ( barcode, 13 );
	return barcode;

EndFunction

Function symbol ( Barcode, Class )

	even = 0;
	odd = 0;
	count = ? ( Class = 13, 6, 4);
	for i = 1 to count do
		if ( Class <> 8
			or i <> count) then
			even = even + Number ( Mid ( Barcode, 2 * i, 1 ) );
		endif;
		odd = odd + Number ( Mid ( Barcode, 2 * i - 1, 1 ) );
	enddo;
	if ( Class = 13 ) then
		even = even * 3;
	else
		odd = odd * 3;
	endif;
	control = 10 - ( even + odd ) % 10;
	return ? ( control = 10, "0", String ( control ) );

EndFunction
