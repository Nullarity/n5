
&AtServer
Procedure Read ( Form ) export
	
	env = newEnv ();
	getData ( env, Form.Object );
	fillInvoice ( Form, env.Fields );
	
EndProcedure

&AtServer
Function newEnv () 

	env = undefined;
	SQL.Init ( env );
	return env;

EndFunction

&AtServer
Procedure getData ( Env, Object ) 

	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Object.Ref );
	SetPrivilegedMode ( true );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure sqlFields ( Env ) 

	s = "
	|// @Fields
	|select top 1 Records.Ref as Ref, Records.Status as Status
	|from Document.InvoiceRecord as Records
	|where Records.Base = &Ref
	|and not Records.DeletionMark
	|order by Records.Date desc
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure fillInvoice ( Form, Fields ) 

	if ( Fields = undefined ) then
		Form.InvoiceRecord = undefined;
		status = undefined;
	else
		Form.InvoiceRecord = Fields.Ref;
		status = Fields.Status;
	endif;
	Form.FormStatus = status;
	Form.ChangesDisallowed = not IsInRole ( Metadata.Roles.ModifyIssuedInvoices )
	and ( status = Enums.FormStatuses.Waiting
	or status = Enums.FormStatuses.Unloaded
	or status = Enums.FormStatuses.Printed
	or status = Enums.FormStatuses.Submitted
	or status = Enums.FormStatuses.Returned
	);

EndProcedure

&AtServer
Procedure Fill ( Object, Base ) export
	
	type = TypeOf ( Base.Ref );
	if ( type = Type ( "DocumentRef.Transfer" ) ) then
		env = getEnv ( Object, "Transfer", true );
		fillByTransfer ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.Invoice" ) ) then
		env = getEnv ( Object, "Invoice" );
		fillByInvoice ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.Sale" ) ) then
		env = getEnv ( Object, "Sale" );
		fillBySale ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.LVITransfer" ) ) then
		env = getEnv ( Object, "LVITransfer" );
		fillByLVI ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.VendorReturn" ) ) then
		env = getEnv ( Object, "VendorReturn" );
		fillByVendorReturn ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.WriteOff" ) ) then
		env = getEnv ( Object, "WriteOff", true );
		fillByWriteOff ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.Return" ) ) then
		env = getEnv ( Object, "Return" );
		fillByReturn ( env, Object, Base );
	elsif ( type = Type ( "DocumentRef.AdjustDebts" ) ) then
		env = getEnv ( Object, "AdjustDebts" );
		fillByAdjustDebts ( env, Object, Base );
	endif;
	
EndProcedure

&AtServer
Function getEnv ( Object, Table, Transfer = false ) 

	env = newEnv ();
	env.Insert ( "IsNew", Object.Ref.IsEmpty () );
	env.Insert ( "Transfer", Transfer );
	env.Insert ( "Table", Table );
	return env;

EndFunction

#region Filling

&AtServer
Procedure fillByTransfer ( Env, Object, Base ) 

	headerByBase ( Object, Base );
	getDataTransfer ( Env, Base );
	fillHeader ( Env, Object );
	fillItems ( Env, Object );

EndProcedure

&AtServer
Procedure headerByBase ( Object, Base ) 

	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Currency = Base.Currency;
	rate = Base.Rate;
	Object.Rate = ? ( rate = 0, 1, rate );
	factor = Base.Factor;
	Object.Factor = ? ( factor = 0, 1, factor );
	Object.Prices = Base.Prices;
	Object.Amount = Base.Amount;
	Object.VAT = Base.VAT;
	Object.VATUse = Base.VATUse;
	fillHeaderCommon ( Object, Base );

EndProcedure

&AtServer
Procedure fillHeaderCommon ( Object, Base ) 

	if ( Object.Ref.IsEmpty () ) then
		Object.Creator = Base.Creator;
		Object.Base = Base.Ref;
		Object.Memo = Base.Memo;
		Object.Account = DF.Pick ( Base.Company, "BankAccount" );
	else
		Object.DeletionMark = false;
	endif;

EndProcedure

&AtServer
Procedure getDataTransfer ( Env, Base ) 

	sqlFieldsTransfer ( Env );
	sqlItems ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsTransfer ( Env )
	
	s = "
	|// @Fields
	|select Documents.Sender as LoadingPoint, Documents.Company as Customer, Documents.Receiver as UnloadingPoint";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Receiver.Address as UnloadingAddress, Documents.Company.BankAccount as CustomerAccount,
		|	Documents.Sender.Address as LoadingAddress, true as Transfer, &Transfer as Redirects";
	endif;
	s = s + "
	|from Document.Transfer as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure sqlItems ( Env )
	
	s = "
	|// #Items
	|select *";
	if ( Env.Transfer ) then
		s = s + ", Item.Social as Social"; 
	endif;
	s = s + "
	|from Document." + Env.Table + ".Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure getTables ( Env, Base ) 

	q = Env.Q;
	q.SetParameter ( "Ref", Base.Ref );
	q.SetParameter ( "Company", Base.Company );
	q.SetParameter ( "Transfer", Output.Transfer () );
	SQL.Perform ( Env );

EndProcedure

&AtServer
Procedure fillHeader ( Env, Object ) 

	FillPropertyValues ( Object, Env.Fields );

EndProcedure

&AtServer
Procedure fillItems ( Env, Object ) 

	items = Object.Items;
	items.Clear ();
	for each row in Env.Items do
		newRow = items.Add ();
		FillPropertyValues ( newRow, row );
	enddo;

EndProcedure

&AtServer
Procedure fillByInvoice ( Env, Object, Base ) 

	headerByBase ( Object, Base );
	getDataInvoice ( Env, Base );
	fillHeader ( Env, Object );
	fillItems ( Env, Object );
	fillServices ( Env, Object );
	fillDiscounts ( Env, Object );

EndProcedure

&AtServer
Procedure getDataInvoice ( Env, Base ) 

	sqlFieldsInvoice ( Env );
	sqlItems ( Env );
	sqlServices ( Env );
	sqlDiscounts ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsInvoice ( Env )
	
	s = "
	|// @Fields
	|select Documents.Warehouse as LoadingPoint, Documents.Customer as UnloadingPoint, Documents.Customer as Customer";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Date as DeliveryDate, Documents.Customer.ShippingAddress as UnloadingAddress,
		|	true as ShowServices, Documents.Warehouse.Address as LoadingAddress,
		|	Documents.Contract.CustomerBank as CustomerAccount";
	endif;
	s = s + "
	|from Document.Invoice as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure sqlServices ( Env )
	
	s = "
	|// #Services
	|select Services.Item as Item, Services.Description as Description, Services.Amount as Amount, Services.Feature as Feature, 
	|	Services.Price as Price, Services.Prices as Prices, Services.Quantity as Quantity, 
	|	Services.Total as Total, Services.VAT as VAT, Services.VATCode as VATCode, Services.VATRate as VATRate 
	|from Document.Invoice.Services as Services
	|where Services.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure sqlDiscounts ( Env )
	
	s = "
	|// #Discounts
	|select Discounts.Item as Item, Discounts.Document as Document, Discounts.Detail as Detail,
	|	Discounts.VATCode as VATCode, Discounts.VATRate as VATRate, Discounts.Amount as Amount, Discounts.VAT as VAT
	|from Document.Invoice.Discounts as Discounts
	|where Discounts.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure

&AtServer
Procedure fillServices ( Env, Object ) 

	services = Object.Services;
	services.Clear ();
	for each row in Env.Services do
		newRow = services.Add ();
		FillPropertyValues ( newRow, row );
	enddo;

EndProcedure

&AtServer
Procedure fillDiscounts ( Env, Object ) 

	discounts = Object.Discounts;
	discounts.Clear ();
	for each row in Env.Discounts do
		newRow = discounts.Add ();
		FillPropertyValues ( newRow, row );
	enddo;

EndProcedure

&AtServer
Procedure fillBySale ( Env, Object, Base ) 

	headerBySale ( Object, Base );
	getDataSale ( Env, Base );
	fillHeader ( Env, Object );
	fillItems ( Env, Object );

EndProcedure

&AtServer
Procedure headerBySale ( Object, Base ) 

	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Currency = Application.Currency ();
	Object.Prices = Base.Prices;
	Object.Amount = Base.Amount;
	Object.VAT = Base.VAT;
	Object.VATUse = Base.VATUse;
	if ( Object.Ref.IsEmpty () ) then
		Object.Customer = Catalogs.Organizations.EmptyRef ();
	endif;
	fillHeaderCommon ( Object, Base );

EndProcedure

&AtServer
Procedure getDataSale ( Env, Base ) 

	sqlFieldsSale ( Env );
	sqlItems ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsSale ( Env )
	
	s = "
	|// @Fields
	|select Documents.Warehouse as LoadingPoint";
	if ( Env.IsNew ) then
		s = s + ",
		|	false as ShowServices, Documents.Warehouse.Address as LoadingAddress, Documents.Date as DeliveryDate";
	endif;
	s = s + "
	|from Document.Sale as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillByLVI ( Env, Object, Base ) 

	headerByLVI ( Object, Base );
	getDataLVI ( env, Base );
	fillHeader ( env, Object );
	fillItems ( env, Object );

EndProcedure

&AtServer
Procedure headerByLVI ( Object, Base ) 

	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Rate = 1;
	Object.Factor = 1;
	fillHeaderCommon ( Object, Base );

EndProcedure

&AtServer
Procedure getDataLVI ( Env, Base ) 

	sqlFieldsLVI ( Env );
	sqlItemsLVI ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsLVI ( Env )
	
	s = "
	|// @Fields
	|select Documents.Company as Customer, Constants.Currency as Currency, Documents.Company.CostPrices as Prices";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Company.BankAccount as CustomerAccount, true as Transfer, &Transfer as Redirects";
	endif;
	s = s + "
	|from Document.LVITransfer as Documents
	|	//
	|	//	Constants
	|	//
	|	left join Constants as Constants
	|	on true
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure sqlItemsLVI ( Env )
	
	s = "
	|// #Items
	|select Items.Item as Item, Items.Capacity as Capacity, Items.Feature as Feature, Items.Package as Package, 
	|	Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg, Items.Item.Social as Social
	|from Document.LVITransfer.Items as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillByVendorReturn ( Env, Object, Base ) 

	headerByVendorReturn ( Object, Base );
	getDataVendorReturn ( env, Base );
	fillHeader ( env, Object );
	fillItems ( env, Object );

EndProcedure

&AtServer
Procedure headerByVendorReturn ( Object, Base )
	
	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Currency = Base.Currency;
	rate = Base.Rate;
	Object.Rate = ? ( rate = 0, 1, rate );
	factor = Base.Factor;
	Object.Factor = ? ( factor = 0, 1, factor );
	Object.Amount = Base.Amount;
	Object.VAT = Base.VAT;
	Object.VATUse = Base.VATUse;
	fillHeaderCommon ( Object, Base );	
	
EndProcedure

&AtServer
Procedure getDataVendorReturn ( Env, Base )
	
	sqlFieldsVendorReturn ( Env );
	sqlItemsVendorReturn ( Env );
	getTables ( Env, Base );
	
EndProcedure

&AtServer
Procedure sqlFieldsVendorReturn ( Env )
	
	s = "
	|// @Fields
	|select Documents.Warehouse as LoadingPoint, Documents.Vendor as UnloadingPoint, Documents.Vendor as Customer";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Vendor.ShippingAddress as UnloadingAddress, Documents.Contract.VendorBank as CustomerAccount,
		|	Documents.Warehouse.Address as LoadingAddress, Documents.Date as DeliveryDate,
		|	true as Transfer, &Transfer as Redirects";
	endif;
	s = s + "
	|from Document.VendorReturn as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure sqlItemsVendorReturn ( Env )
	
	s = "
	|// #Items
	|select Items.Item as Item, Items.Amount as Amount, Items.Capacity as Capacity, Items.Feature as Feature, Items.Package as Package, 
	|	Items.Price as Price, Items.Prices as Prices, Items.Quantity as Quantity, Items.QuantityPkg as QuantityPkg, Items.Series as Series, 
	|	Items.Total as Total, Items.VAT as VAT, Items.VATCode as VATCode, Items.VATRate as VATRate, Items.ProducerPrice as ProducerPrice, 
	|	Items.Social as Social 
	|from Document.VendorReturn.Items as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Item, Items.Amount, 1, value ( Catalog.Features.EmptyRef ), value ( Catalog.Packages.EmptyRef ), 
	|	0, value ( Catalog.Prices.EmptyRef ), 1, 1, value ( Catalog.Series.EmptyRef ), 
	|	Items.Total, Items.VAT, Items.VATCode, Items.VATRate, 0, false
	|from Document.VendorReturn.FixedAssets as Items
	|where Items.Ref = &Ref
	|union all
	|select Items.Item, Items.Amount, 0, value ( Catalog.Features.EmptyRef ), value ( Catalog.Packages.EmptyRef ), 
	|	0, value ( Catalog.Prices.EmptyRef ), 1, 0, value ( Catalog.Series.EmptyRef ), 
	|	Items.Total, Items.VAT, Items.VATCode, Items.VATRate, 0, false
	|from Document.VendorReturn.IntangibleAssets as Items
	|where Items.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillByWriteOff ( Env, Object, Base ) 

	headerByBase ( Object, Base );
	getDataWriteOff ( Env, Base );
	fillHeader ( Env, Object );
	fillItems ( Env, Object );

EndProcedure

&AtServer
Procedure getDataWriteOff ( Env, Base ) 

	sqlFieldsWriteOff ( Env );
	sqlItems ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsWriteOff ( Env )
	
	s = "
	|// @Fields
	|select Documents.Warehouse as LoadingPoint, Documents.Customer as UnloadingPoint, Documents.Customer as Customer";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Date as DeliveryDate, Documents.Customer.ShippingAddress as UnloadingAddress,
		|	&Transfer as Redirects, Documents.Warehouse.Address as LoadingAddress,
		|	Documents.Contract.CustomerBank as CustomerAccount";
	endif;
	s = s + "
	|from Document.WriteOff as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillByReturn ( Env, Object, Base ) 

	headerByReturn ( Object, Base );
	getDataReturn ( Env, Base );
	fillHeader ( Env, Object );
	fillReturnItems ( Env, Object );

EndProcedure

&AtServer
Procedure headerByReturn ( Object, Base ) 

	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Currency = Base.Currency;
	rate = Base.Rate;
	Object.Rate = ? ( rate = 0, 1, rate );
	factor = Base.Factor;
	Object.Factor = ? ( factor = 0, 1, factor );
	Object.Amount = - Base.Amount;
	Object.VAT = - Base.VAT;
	Object.VATUse = Base.VATUse;
	fillHeaderCommon ( Object, Base );

EndProcedure

&AtServer
Procedure getDataReturn ( Env, Base ) 

	sqlFieldsReturn ( Env );
	sqlItems ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsReturn ( Env )
	
	s = "
	|// @Fields
	|select Documents.Warehouse as LoadingPoint, Documents.Customer as UnloadingPoint, Documents.Customer as Customer";
	if ( Env.IsNew ) then
		s = s + ",
		|	Documents.Customer.ShippingAddress as UnloadingAddress, Documents.Date as DeliveryDate,
		|	Documents.Warehouse.Address as LoadingAddress, Documents.Contract.CustomerBank as CustomerAccount";
	endif;
	s = s + "
	|from Document.Return as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillReturnItems ( Env, Object ) 

	items = Object.Items;
	items.Clear ();
	for each row in Env.Items do
		newRow = items.Add ();
		FillPropertyValues ( newRow, row );
		newRow.Quantity = - newRow.Quantity;
		newRow.QuantityPkg = - newRow.QuantityPkg;
		newRow.Amount = - newRow.Amount;
		newRow.VAT = - newRow.VAT;
		newRow.Total = - newRow.Total;
	enddo;

EndProcedure

&AtServer
Procedure fillByAdjustDebts ( Env, Object, Base ) 

	headerByAdjustDebts ( Object, Base );
	getDataAdjustDebts ( Env, Base );
	fillAdjustDebtsServices ( Env, Object );
	fillAdjustDebtsHeader ( Env, Object );

EndProcedure

&AtServer
Procedure headerByAdjustDebts ( Object, Base ) 

	Object.Date = Base.Date;
	Object.Company = Base.Company;
	Object.Currency = Base.Currency;
	rate = Base.Rate;
	Object.Rate = ? ( rate = 0, 1, rate );
	factor = Base.Factor;
	Object.Factor = ? ( factor = 0, 1, factor );
	Object.VATUse = 1;
	fillHeaderCommon ( Object, Base );

EndProcedure

&AtServer
Procedure getDataAdjustDebts ( Env, Base ) 

	sqlFieldsAdjustDebts ( Env );
	sqlAdjustDebtsServices ( Env );
	getTables ( Env, Base );

EndProcedure

&AtServer
Procedure sqlFieldsAdjustDebts ( Env )
	
	s = "
	|// @Fields
	|select Documents.Customer as UnloadingPoint, Documents.Customer as Customer,
	|	Documents.Reversal as Reversal, Documents.Type as Type";
	if ( Env.IsNew ) then
		s = s + ",
		|	true as ShowServices,
		|	Documents.Customer.ShippingAddress as UnloadingAddress, Documents.Date as DeliveryDate,
		|	Documents.Contract.CustomerBank as CustomerAccount";
	endif;
	s = s + "
	|from Document.AdjustDebts as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure sqlAdjustDebtsServices ( Env )
	
	s = "
	|// #Services
	|select Adjustments.AmountLocal as Total, Adjustments.VATLocal as VAT, Adjustments.AmountLocal - Adjustments.VATLocal as Amount,
	|	Adjustments.VATCode as VATCode, Adjustments.VATRate as VATRate, Adjustments.Item as Item,
	|	Adjustments.Description as Description
	|from Document.AdjustDebts.Adjustments as Adjustments
	|where Adjustments.Ref = &Ref
	|and Adjustments.VATCode <> value ( Catalog.VAT.EmptyRef )
	|union all
	|select Accounting.AmountLocal, Accounting.VATLocal, Accounting.AmountLocal - Accounting.VATLocal,
	|	Accounting.VATCode, Accounting.VATRate, Accounting.Item, Accounting.Description
	|from Document.AdjustDebts.Accounting as Accounting
	|where Accounting.Ref = &Ref
	|and Accounting.VATCode <> value ( Catalog.VAT.EmptyRef )
	|";
	Env.Selection.Add ( s );

EndProcedure 

&AtServer
Procedure fillAdjustDebtsServices ( Env, Object ) 

	services = Object.Services;
	services.Clear ();
	fields = Env.Fields;
	if ( fields.Reversal ) then
		reverse = fields.Type = Enums.TypesAdjustDebts.Advance;
	else
		reverse = fields.Type = Enums.TypesAdjustDebts.Debt;
	endif;
	for each row in Env.Services do
		newRow = services.Add ();
		FillPropertyValues ( newRow, row );
		if ( reverse ) then
			newRow.Amount = - newRow.Amount;
			newRow.Total = - newRow.Total;
			newRow.VAT = - newRow.VAT;
			if ( newRow.Quantity = 0 ) then
				newRow.Price = - newRow.Price;
			else
				newRow.Quantity = - newRow.Quantity;
			endif;
		endif;
	enddo;

EndProcedure

&AtServer
Procedure fillAdjustDebtsHeader ( Env, Object )

	fillHeader ( Env, Object );
	services = Object.Services;
	Object.VAT = services.Total ( "VAT" );
	Object.Amount = services.Total ( "Total" );

EndProcedure

#endregion

&AtServer
Procedure Sync ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif; 
	SetPrivilegedMode ( true );
	ref = InvoiceRecordsSrv.Search ( Object.Ref );
	if ( ref <> undefined ) then
		update ( ref.GetObject (), Object );
	endif;
	
EndProcedure 

&AtServer
Function syncing ( Object )
	
	sync = undefined;
	Object.AdditionalProperties.Property ( Enum.AdditionalPropertiesSyncing (), sync );
	return sync <> undefined
	and sync;
	
EndFunction 

&AtServer
Procedure update ( Object, Base )
	
	InvoiceRecords.Fill ( Object, Base );
	markSyncing ( Object );
	Object.Write ();
	
EndProcedure

&AtServer
Procedure markSyncing ( Object )
	
	Object.AdditionalProperties.Insert ( Enum.AdditionalPropertiesSyncing (), true );
	
EndProcedure 

&AtServer
Procedure Delete ( Object ) export
	
	if ( syncing ( Object ) ) then
		return;
	endif;
	ref = InvoiceRecordsSrv.Search ( Object.Ref );
	if ( ref <> undefined ) then
		remove ( ref );
	endif;

EndProcedure

&AtServer
Procedure remove ( Ref )
	
	obj = Ref.GetObject ();
	markSyncing ( obj );
	obj.SetDeletionMark ( true );
	
EndProcedure 
