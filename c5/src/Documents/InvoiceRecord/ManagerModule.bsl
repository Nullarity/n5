#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	DocumentPresentation.StandardFields(Fields, StandardProcessing);
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	DocumentPresentation.StandardPresentation(Metadata.Documents.InvoiceRecord.Synonym, Data, Presentation, StandardProcessing);
	
EndProcedure

#region Printing

Function Print(Params, Env) export
	
	Print.SetFooter(Params.TabDoc);
	getData(Params, Env);
	if (not FormsPrint.Check(Params.Reference, Env.Fields.Status)) then
		return false;
	endif;
	setTemplates(Env);
	setPageSettings(Params, Env);
	putHeader(Params, Env);
	putRow(Params, Env, Env.First);
	putFooter(Params, Env);
	putAttachments(Params, Env);
	putBack(Params, Env);
	return true;
	
EndFunction

Procedure getData(Params, Env)
	
	sqlFields(Env);
	getFields(Params, Env);
	defineAmount(Env);
	sqlItems(Env);
	getTables(Env);
	distributeItems(Env);
	setFeatures(Env);
	Env.Insert("IsAttachment", false);
	
EndProcedure

Procedure sqlFields(Env)
	
	s = "
		|// @Fields
		|select top 1 Documents.Number as Number, Documents.Company.FullDescription as Company,
		|	Documents.Company.CodeFiscal as CodeFiscal, Documents.Status as Status,
		|	case when Documents.Type = value ( Enum.Print.Portrait ) then true else false end as Portrait,
		|	case when Documents.Type = value ( Enum.Print.ElectronicPortrait ) then true else false end as ElectronicPortrait,
		|	case when Documents.Type = value ( Enum.Print.ElectronicLandscape ) then true else false end as ElectronicLandscape,
		|	case when Documents.Type = value ( Enum.Print.Landscape ) then true else false end as Landscape,
		|	isnull ( Documents.Account.AccountNumber, """" ) as Account, Documents.AttachedDocuments as AttachedDocuments, 
		|	isnull ( Documents.Carrier.FullDescription, """" ) as Carrier, Documents.Currency as Currency, Constants.Currency as LocalCurrency, 
		|	Documents.Delegated as Delegated, isnull ( Documents.Dispatcher.Description, """" ) as Dispatcher, 
		|	isnull ( Documents.Driver.Description, """" ) as Driver, Documents.Factor as Factor, Documents.FirstPageRows as FirstPageRows, 
		|	isnull ( Documents.LoadingAddress.Presentation, """" ) as LoadingAddress, Documents.AttachmentRows as AttachmentRows,
		|	Documents.PowerAttorneyDate as PowerAttorneyDate, Documents.PowerAttorneyNumber as PowerAttorneyNumber, 
		|	Documents.PowerAttorneySeries as PowerAttorneySeries, Documents.Rate as Rate, isnull ( Documents.Customer.FullDescription, """" ) as Customer,
		|	isnull ( Documents.CustomerAccount.AccountNumber, """" ) as CustomerAccount, Documents.Redirects as Redirects,
		|	isnull ( Documents.Storekeeper.Description, """" ) as Storekeeper, isnull ( Documents.Customer.VATCode, """" ) as CustomerVATCode,
		|	isnull ( Documents.UnloadingAddress.Presentation, """" ) as UnloadingAddress, 	Documents.WaybillDate as WaybillDate, 
		|	Documents.WaybillNumber as WaybillNumber, Documents.WaybillSeries as WaybillSeries,
		|	isnull ( Documents.Account.Bank.Description, """" ) as Bank, isnull ( Documents.Company.PaymentAddress.Presentation, """" ) as CompanyAddress, 
		|	Contacts.BusinessPhone as BusinessPhone, ContactsCustomer.BusinessPhone as CustomerBusinessPhone,
		|	isnull ( Documents.Customer.PaymentAddress.Presentation, """" ) as CustomerAddress, Documents.Date as Date,
		|	isnull ( Documents.CustomerAccount.Bank.Description, """" ) as CustomerBank, isnull ( Documents.Customer.CodeFiscal, """" ) as CustomerCodeFiscal,
		|	isnull ( Documents.CustomerAccount.Bank.Code, """" ) as CustomerBankCode, isnull ( Documents.Account.Bank.Code, """" ) as BankCode,
		|	Documents.DeliveryDate as DeliveryDate, isnull ( Documents.Carrier.CodeFiscal, """" ) as CarrierCodeFiscal,
		|	isnull ( Documents.Carrier.VATCode, """" ) as CarrierVATCode, isnull ( Documents.Company.VATCode, """" ) as VATCode,
		|	isnull ( PersonnelDispatcher.Position.Description, """" ) as DispatcherPosition, isnull ( PersonnelDriver.Position.Description, """" ) as DriverPosition,
		|	isnull ( PersonnelStorekeeper.Position.Description, """" ) as StorekeeperPosition, Documents.PrintBack as PrintBack,
		|	case when Logos.Logo is null then false else true end as LogoLoaded,  Logos.Logo as Logo
		|from Document.InvoiceRecord as Documents
		|	//
		|	// Constants
		|	//
		|	join Constants as Constants
		|	on true
		|	//
		|	// Contacts
		|	//
		|	left join Catalog.Contacts as Contacts
		|	on Contacts.Owner = Documents.Company
		|	and not Contacts.DeletionMark
		|	and Contacts.ContactType = value ( Catalog.ContactTypes.Director )
		|	//
		|	// Contacts Customer
		|	//
		|	left join Catalog.Contacts as ContactsCustomer
		|	on ContactsCustomer.Owner = Documents.Customer
		|	and not ContactsCustomer.DeletionMark
		|	and ContactsCustomer.ContactType = value ( Catalog.ContactTypes.Director )
		|	//
		|	// Personnel Dispatcher
		|	//
		|	left join InformationRegister.Personnel as PersonnelDispatcher
		|	on PersonnelDispatcher.Employee = Documents.Dispatcher
		|	and Documents.Dispatcher <> value ( Catalog.Employees.EmptyRef )
		|	//
		|	// Personnel Driver
		|	//
		|	left join InformationRegister.Personnel as PersonnelDriver
		|	on PersonnelDriver.Employee = Documents.Driver
		|	and Documents.Driver <> value ( Catalog.Employees.EmptyRef )
		|	//
		|	// Personnel Storekeeper
		|	//
		|	left join InformationRegister.Personnel as PersonnelStorekeeper
		|	on PersonnelStorekeeper.Employee = Documents.Storekeeper
		|	and Documents.Storekeeper <> value ( Catalog.Employees.EmptyRef )
		|	//
		|	// Logos
		|	//
		|	left join InformationRegister.Logos as Logos
		|	on Logos.Company = Documents.Company
		|where Documents.Ref = &Ref 
		|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getFields(Params, Env)
	
	Env.Q.SetParameter("Ref", Params.Reference);
	SQL.Perform(Env);
	
EndProcedure

Procedure defineAmount(Env)
	
	list = new Structure();
	Env.Insert("AmountFields", list);
	fields = Env.Fields;
	foreign = fields.Currency <> fields.LocalCurrency;
	total = "Total";
	vat = "VAT";
	producerPrice = "ProducerPrice";
	if (foreign) then
		rate = " * &Rate / &Factor";
		total = total + rate;
		vat = vat + rate;
		producerPrice = producerPrice + rate;
	endif;
	list.Insert("Total", "cast ( " + total + " as Number ( 15, 2 ) )");
	list.Insert("VAT", "cast ( " + vat + " as Number ( 15, 2 ) )");
	list.Insert("ProducerPrice", "cast ( " + producerPrice + " as Number ( 15, 2 ) )");
	
EndProcedure

Procedure sqlItems(Env)
	
	amountFields = Env.AmountFields;
	total = amountFields.Total;
	vat = amountFields.VAT;
	amount = total + " - " + vat;
	producerPrice = amountFields.ProducerPrice;
	s = "
		|// #Items
		|select case when Items.Item refs Catalog.Items and Items.Item.CountPackages then Items.Capacity else """" end as Capacity,
		|	presentation ( case when Items.Package = value ( Catalog.Packages.EmptyRef ) then Items.Item.Unit else Items.Package end ) as Unit,
		|	Items.QuantityPkg as Quantity,
		|	case when Items.Item refs Catalog.Items then
		|		( case when Items.Item.CountPackages then Items.QuantityPkg else Items.Quantity end * Items.Item.Weight ) / 1000
		|		when Items.Item refs Catalog.FixedAssets then ( Items.Quantity * Items.Item.Weight ) / 1000
		|		else 0
		|	end as Weight, " + total + " as Total, " + vat + " as VAT, 
		|	case 
		|		when case when Items.Item refs Catalog.Items then Items.QuantityPkg else Items.Quantity end = 0 then " + amount + "
		|		else (" + amount + ") / case when Items.Item refs Catalog.Items then Items.QuantityPkg else Items.Quantity end 
		|	end as Price, " + amount + " as Amount, 
		|	case when Items.Item refs Catalog.Items then isnull ( Items.Feature.Description, """" ) else """" end as Feature,
		|	isnull ( Items.Item.FullDescription, """" ) as Item, Items.VATRate as VATRate, false as Empty, Items.OtherInfo as OtherInfo,
		|	Items.Social as Social, " + producerPrice + " as ProducerPrice, Items.ExtraCharge as ExtraCharge, Items.Item.OfficialCode as OfficialCode
		|from Document.InvoiceRecord.Items as Items
		|where Items.Ref = &Ref 
		|union all
		|select """", Services.Item.Unit.Code, Services.Quantity, 0, " + total + ", " + vat + ", 
		|	case when Services.Quantity = 0 then " + amount + " else (" + amount + ") /  Services.Quantity end, 
		|	" + amount + ", isnull ( Services.Feature.Description, """" ), Services.Description,
		|	Services.VATRate, false, Services.OtherInfo, false, 0, 0, """"
		|from Document.InvoiceRecord.Services as Services
		|where Services.Ref = &Ref 
		|";
	Env.Selection.Add(s);
	
EndProcedure

Procedure getTables(Env)
	
	q = Env.Q;
	fields = Env.Fields;
	q.SetParameter("Rate", fields.Rate);
	q.SetParameter("Factor", fields.Factor);
	SQL.Perform(Env);
	
EndProcedure

Procedure distributeItems(Env)
	
	items = Env.Items;
	first = items.CopyColumns();
	tables = new Array();
	fields = Env.Fields;
	firstPageRows = fields.FirstPageRows;
	attachmentRows = fields.AttachmentRows;
	rows = 0;
	for each row in items do
		if (firstPageRows > 0) then
			FillPropertyValues(first.Add(), row);
		else
			if (rows = 0) then
				rows = attachmentRows;
				attachment = items.CopyColumns();
				tables.Add(attachment);
			endif;
			FillPropertyValues(attachment.Add(), row);
			rows = rows - 1;
		endif;
		firstPageRows = firstPageRows - 1;
	enddo;
	addEmptyRows(first, fields.FirstPageRows - first.Count());
	count = tables.Count();
	if (count > 0) then
		last = tables[count - 1];
		addEmptyRows(last, fields.AttachmentRows - last.Count());
	endif;
	Env.Insert("First", first);
	Env.Insert("Attachments", tables);
	
EndProcedure

Procedure addEmptyRows(Table, Difference)
	
	while (Difference > 0) do
		row = Table.Add();
		row.Empty = true;
		Difference = Difference - 1;
	enddo;
	
EndProcedure

Procedure setFeatures(Env)
	
	Env.Insert("Features", Options.Features());
	
EndProcedure

Procedure setTemplates(Env)
	
	fields = Env.Fields;
	if (fields.Portrait) then
		invoice = "Invoice";
		attachment = "Attachment";
	elsif (fields.Landscape) then
		invoice = "InvoiceLandscape";
		attachment = "AttachmentLandscape";
	elsif (fields.ElectronicPortrait) then
		invoice = "InvoiceElectronic";
		attachment = "AttachmentElectronic";
	else
		invoice = "InvoiceElectronicLandscape";
		attachment = "AttachmentElectronicLandscape";
	endif;
	manager = Documents.InvoiceRecord;
	Env.T = manager.GetTemplate(invoice);
	Env.Insert("Attachment", manager.GetTemplate(attachment));
	Env.Insert("Back", manager.GetTemplate("Back"));
	
EndProcedure

Procedure setPageSettings(Params, Env)
	
	tabDoc = Params.TabDoc;
	fields = Env.Fields;
	if (fields.Portrait
			or fields.ElectronicPortrait) then
		tabDoc.PageOrientation = PageOrientation.Portrait;
	else
		tabDoc.PageOrientation = PageOrientation.Landscape;
	endif;
	tabDoc.FitToPage = true;
	
EndProcedure

Procedure putHeader(Params, Env)
	
	area = Env.T.GetArea("Header");
	p = area.Parameters;
	fields = Env.Fields;
	p.WaybillSeries = TrimAll(fields.WaybillSeries);
	p.WaybillNumber = TrimAll(fields.WaybillNumber);
	p.WaybillDate = fields.WaybillDate;
	p.Date = fields.Date;
	p.DeliveryDate = fields.DeliveryDate;
	p.Company = getCompany(fields);
	p.Customer = getCustomer(fields);
	if (fields.ElectronicPortrait
			or fields.ElectronicLandscape) then
		number = TrimAll(fields.Number);
		p.Number = number;
		setBarcode(area, number);
		setLogo(area, fields);
	endif;
	p.AttachedDocuments = TrimAll(fields.AttachedDocuments);
	p.CodeFiscal = TrimAll(fields.CodeFiscal);
	p.VATCode = TrimAll(fields.VATCode);
	p.CustomerCodeFiscal = fields.CustomerCodeFiscal;
	p.CustomerVATCode = TrimAll(fields.CustomerVATCode);
	p.CarrierCodeFiscal = fields.CarrierCodeFiscal;
	p.CarrierVATCode = TrimAll(fields.CarrierVATCode);
	p.LoadingAddress = TrimAll(fields.LoadingAddress);
	p.UnloadingAddress = TrimAll(fields.UnloadingAddress);
	p.Redirects = TrimAll(fields.Redirects);
	p.Carrier = TrimAll(fields.Carrier);
	p.PowerAttorneySeries = TrimAll(fields.PowerAttorneySeries);
	p.PowerAttorneyNumber = fields.PowerAttorneyNumber;
	p.PowerAttorneyDate = fields.PowerAttorneyDate;
	p.Delegated = fields.Delegated;
	Params.TabDoc.Put(area);
	
EndProcedure

Function getCompany(Fields)
	
	company = TrimAll(Fields.Company);
	addValue(company, Fields.CompanyAddress);
	addPhone(company, Fields.BusinessPhone);
	addValue(company, bank(Fields.Bank, Fields.BankCode, Fields.Account), ". ");
	return company;
	
EndFunction

Procedure addValue(Field, Value, Separator = ", ")
	
	Value = TrimAll(Value);
	if (not IsBlankString(Value)) then
		Field = Field + Separator + Value;
	endif;
	
EndProcedure

Procedure addPhone(Field, Phone)
	
	Phone = TrimAll(Phone);
	if (not IsBlankString(Phone)) then
		Field = Field + ", tel.: " + Phone;
	endif;
	
EndProcedure

Function bank(Bank, BankCode, Account)
	
	field = Bank;
	BankCode = TrimAll(BankCode);
	if (not IsBlankString(BankCode)) then
		field = field + ", C/B: " + BankCode;
	endif;
	addValue(field, Account);
	return field;
	
EndFunction

Function getCustomer(Fields)
	
	customer = TrimAll(Fields.Customer);
	addValue(customer, Fields.CustomerAddress);
	addPhone(customer, Fields.CustomerBusinessPhone);
	addValue(customer, bank(Fields.CustomerBank, Fields.CustomerBankCode, Fields.CustomerAccount), ". ");
	return customer;
	
EndFunction

Procedure setBarcode(Area, Barcode)
	
	picture = Area.Drawings.Barcode;
	p = PrintBarcodes.GetParams();
	p.Width = picture.Width;
	p.Height = picture.Height;
	p.Barcode = Barcode;
	p.Type = 4;
	Area.Drawings.Barcode.Picture = PrintBarcodes.GetPicture(p);
	
EndProcedure

Procedure setLogo(Area, Fields)
	
	if (Fields.LogoLoaded) then
		Area.Drawings.Logo.Picture = new Picture(Fields.Logo.Get());
	endif;
	
EndProcedure

Procedure putRow(Params, Env, Table)
	
	if (Env.IsAttachment) then
		t = Env.Attachment;
	else
		t = Env.T;
	endif;
	area = t.GetArea("Row");
	emptyRow = t.GetArea("EmptyRow");
	p = area.Parameters;
	tabDoc = Params.TabDoc;
	features = Env.Features;
	for each row in Table do
		if (row.Empty) then
			tabDoc.Put(emptyRow);
			continue;
		endif;
		p.Fill(row);
		feature = TrimAll(row.Feature);
		if (features
				and not IsBlankString(feature)) then
			p.Item = TrimAll(row.Item) + " (" + feature + ")";
		else
			p.Item = TrimAll(row.Item);
		endif;
		if (row.Social) then
			p.OtherInfo = "" + row.ProducerPrice + "/" + Format(row.ExtraCharge, "NFD=2; NZ=") + " " + row.OtherInfo;
		endif;
		tabDoc.Put(area);
	enddo;
	
EndProcedure

Procedure putFooter(Params, Env)
	
	area = Env.T.GetArea("Footer");
	p = area.Parameters;
	fields = Env.Fields;
	items = Env.Items;
	p.TotalTotal = items.Total("Total");
	p.TotalAmount = items.Total("Amount");
	p.TotalVAT = items.Total("VAT");
	p.TotalWeight = items.Total("Weight");
	p.Dispatcher = employee(fields.Dispatcher, fields.DispatcherPosition);
	p.Storekeeper = employee(fields.Storekeeper, fields.StorekeeperPosition);
	p.Driver = employee(fields.Driver, fields.DriverPosition);
	p.Delegated = fields.Delegated;
	table = Env.First;
	p.Amount = table.Total("Amount");
	p.Total = table.Total("Total");
	p.VAT = table.Total("VAT");
	p.Weight = table.Total("Weight");
	tabDoc = Params.TabDoc;
	tabDoc.Put(area);
	tabDoc.PutHorizontalPageBreak();
	
EndProcedure

Function employee(Employee, Position)
	
	return TrimAll(Employee + ?(IsBlankString(Position), "", " - " + Position));
	
EndFunction

Procedure putAttachments(Params, Env)
	
	Env.IsAttachment = true;
	for each table in Env.Attachments do
		putHeaderAttachment(Params, Env);
		putRow(Params, Env, table);
		putFooterAttachment(Params, Env, table);
	enddo;
	
EndProcedure

Procedure putHeaderAttachment(Params, Env)
	
	area = Env.Attachment.GetArea("Header");
	p = area.Parameters;
	fields = Env.Fields;
	p.CodeFiscal = TrimAll(fields.CodeFiscal);
	number = TrimAll(fields.Number);
	p.Number = number;
	p.Date = fields.Date;
	p.VATCode = fields.VATCode;
	if (fields.ElectronicPortrait
			or fields.ElectronicLandscape) then
		setLogo(area, fields);
	endif;
	Params.TabDoc.Put(area);
	
EndProcedure

Procedure putFooterAttachment(Params, Env, Table)
	
	area = Env.Attachment.GetArea("Footer");
	p = area.Parameters;
	p.Amount = Table.Total("Amount");
	p.Total = Table.Total("Total");
	p.VAT = Table.Total("VAT");
	p.Weight = Table.Total("Weight");
	tabDoc = Params.TabDoc;
	tabDoc.Put(area);
	tabDoc.PutHorizontalPageBreak();
	
EndProcedure

Procedure putBack(Params, Env)
	
	if (not Env.Fields.PrintBack) then
		return;
	endif;
	area = Env.Back.GetArea("Header");
	Params.TabDoc.Put(area);
	
EndProcedure

#endregion

#endif