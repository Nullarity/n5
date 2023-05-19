#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var Parameters export;
var JobKey export;
var Meta;
var Metaname;
var XML;
var TempFile;
var DataReader;
var Invoice;
var Object;
var Fields;
var ItemsTable;
var ServicesTable;
var BenefitsTable;
var EmptyDate;

Procedure Exec() export
	
	init();
	initDataReader();
	initXML();
	BeginTransaction();
	for each Invoice in Parameters.Invoices do
		read();
		unload();
		commit();
	enddo;
	CommitTransaction();
	complete();
	
EndProcedure

Procedure init()
	
	Meta = Metadata();
	Metaname = Meta.FullName();
	TempFile = GetTempFileName();
	EmptyDate = Date(1, 1, 1);
	
EndProcedure

Procedure initDataReader()
	
	s = "
	|select Invoices.Company.CodeFiscal as CompanyCodeFiscal, Invoices.Company.FullDescription as Company,
	|	Invoices.Company.VAT as VATPayer, Invoices.Redirects as Redirects,
	|	isnull ( Invoices.Company.PaymentAddress.Address, """" ) as CompanyAddress,
	|	isnull ( Invoices.Account.Bank.Description, """" ) as CompanyBank,
	|	isnull ( Invoices.Account.Bank.Code, """" ) as CompanyBankCode,
	|	isnull ( Invoices.Account.AccountNumber, """" ) as CompanyAccountNumber,
	|	isnull ( Invoices.Customer.CodeFiscal, """" ) as CustomerCodeFiscal, Invoices.Customer.FullDescription as Customer,
	|	isnull ( Invoices.Customer.PaymentAddress.Address, """" ) as CustomerAddress,
	|	isnull ( Invoices.CustomerAccount.Bank.Description, """" ) as CustomerBank,
	|	isnull ( Invoices.CustomerAccount.Bank.Code, """" ) as CustomerBankCode,
	|	isnull ( Invoices.CustomerAccount.AccountNumber, """" ) as CustomerAccountNumber,
	|	isnull ( Invoices.Carrier.CodeFiscal, """" ) as CarrierCodeFiscal, Invoices.Carrier.FullDescription as Carrier,
	|	isnull ( Invoices.Carrier.PaymentAddress.Address, """" ) as CarrierAddress,
	|	isnull ( Invoices.LoadingAddress.Address, """" ) as LoadingAddress,
	|	isnull ( Invoices.UnloadingAddress.Address, """" ) as UnloadingAddress
	|from Document.InvoiceRecord as Invoices
	|where Invoices.Ref = &Ref
	|;
	|select 1 as Table, Items.Item.Code as Code, Items.Item.FullDescription as Item, Items.Item.Unit.Description as Unit,
	|	isnull ( Items.Package.Description, """" ) as Package, isnull ( Items.Item.Weight, 0 ) as Weight,
	|	Items.Item.SKU as SKU, Items.Feature.Description as Feature, Items.Series.Description as Series
	|from Document.InvoiceRecord.Items as Items
	|where Items.Ref = &Ref
	|order by Items.LineNumber
	|;
	|select Services.Item.Code as Code, Services.Description as Item, Services.Item.Unit.Description as Unit
	|from Document.InvoiceRecord.Services as Services
	|where Services.Ref = &Ref
	|order by Services.LineNumber
	|;
	|select Discounts.Item.Code as Code, Discounts.Item.FullDescription as Item, Discounts.Item.Unit.Description as Unit
	|from Document.InvoiceRecord.Discounts as Discounts
	|where Discounts.Ref = &Ref
	|order by Discounts.LineNumber
	|";
	DataReader = new Query(s);
	
EndProcedure

Procedure initXML()
	
	XML = new XMLWriter();
	XML.OpenFile(TempFile, , false);
	XML.WriteXMLDeclaration();
	XML.WriteStartElement("Documents");
	
EndProcedure

Procedure read()
	
	SetPrivilegedMode(true);
	Object = Invoice.GetObject();
	DataReader.SetParameter("Ref", Invoice);
	data = DataReader.ExecuteBatch();
	Fields = data[0].Unload()[0];
	ItemsTable = data[1].Unload();
	ServicesTable = data[2].Unload();
	BenefitsTable = data[3].Unload();
	
EndProcedure

Procedure unload()
	
	XML.WriteStartElement("Document");
	XML.WriteStartElement("SupplierInfo");
	XML.WriteStartElement("DeliveryDate");
	XML.WriteText(XMLString(Object.DeliveryDate));
	XML.WriteEndElement();
	XML.WriteStartElement("Supplier");
	writeAttribute("IDNO", Fields.CompanyCodeFiscal, true);
	writeAttribute("Title", Fields.Company);
	writeAttribute("Address", Fields.CompanyAddress);
	XML.WriteStartElement("BankAccount");
	writeAttribute("BranchTitle", Fields.CompanyBank);
	writeAttribute("BranchCode", TrimR(Fields.CompanyBankCode));
	writeAttribute("Account", Fields.CompanyAccountNumber);
	XML.WriteStartElement("IsManual");
	XML.WriteText("false");
	XML.WriteEndElement();
	XML.WriteEndElement();
	XML.WriteEndElement();
	XML.WriteStartElement("Buyer");
	writeAttribute("IDNO", Fields.CustomerCodeFiscal, true);
	writeAttribute("Title", Fields.Customer);
	writeAttribute("Address", Fields.CustomerAddress);
	XML.WriteStartElement("BankAccount");
	writeAttribute("BranchTitle", Fields.CustomerBank);
	writeAttribute("BranchCode", TrimR(Fields.CustomerBankCode));
	writeAttribute("Account", Fields.CustomerAccountNumber);
	XML.WriteStartElement("IsManual");
	XML.WriteText("false");
	XML.WriteEndElement();
	XML.WriteEndElement();
	XML.WriteEndElement();
	if (Object.Carrier <> undefined) then
		XML.WriteStartElement("Transporter");
		writeAttribute("IDNO", Fields.CarrierCodeFiscal);
		writeAttribute("Title", Fields.Carrier);
		writeAttribute("Address", Fields.CarrierAddress);
		XML.WriteStartElement("BankAccount");
		writeAttribute("BranchTitle", "", true);
		writeAttribute("BranchCode", "", true);
		writeAttribute("Account", "", true);
		XML.WriteStartElement("IsManual");
		XML.WriteText("false");
		XML.WriteEndElement();
		XML.WriteEndElement();
		XML.WriteEndElement();
	endif;
	XML.WriteStartElement("Notes");
	XML.WriteText("" + Object.Ref.UUID());
	XML.WriteEndElement();
	value = Object.AttachedDocuments;
	if (value <> "") then
		XML.WriteStartElement("AttachedDocuments");
		XML.WriteText(value);
		XML.WriteEndElement();
	endif;
	if (Object.PowerAttorneyDate <> EmptyDate
			and Object.PowerAttorneySeries <> ""
			and Object.PowerAttorneyNumber <> "") then
		XML.WriteStartElement("DelegateSeria");
		XML.WriteText(Object.PowerAttorneySeries);
		XML.WriteEndElement();
		XML.WriteStartElement("DelegateNumber");
		XML.WriteText(Object.PowerAttorneyNumber);
		XML.WriteEndElement();
		XML.WriteStartElement("DelegateName");
		XML.WriteText(Object.Delegated);
		XML.WriteEndElement();
		XML.WriteStartElement("DelegateDate");
		XML.WriteText(XMLString(Object.PowerAttorneyDate));
		XML.WriteEndElement();
	endif;
	if (Object.WaybillDate <> EmptyDate
			and Object.WaybillSeries <> ""
			and Object.WaybillNumber <> "") then
		XML.WriteStartElement("VehicleLogbook");
		XML.WriteStartElement("IssuedDate");
		XML.WriteText(XMLString(Object.WaybillDate));
		XML.WriteEndElement();
		XML.WriteStartElement("Seria");
		XML.WriteText(Object.WaybillSeries);
		XML.WriteEndElement();
		XML.WriteStartElement("Number");
		XML.WriteText(Object.WaybillNumber);
		XML.WriteEndElement();
		XML.WriteEndElement();
	endif;
	value = Fields.LoadingAddress;
	if (ValueIsFilled(value)) then
		XML.WriteStartElement("LoadingPoint");
		XML.WriteText(value);
		XML.WriteEndElement();
	endif;
	value = Fields.UnloadingAddress;
	if (ValueIsFilled(value)) then
		XML.WriteStartElement("UnloadingPoint");
		XML.WriteText(value);
		XML.WriteEndElement();
	endif;
	value = Fields.Redirects;
	if (value <> "") then
		XML.WriteStartElement("Redirections");
		XML.WriteText(value);
		XML.WriteEndElement();
	endif;
	rate = Object.Rate;
	factor = Object.Factor;
	XML.WriteStartElement("Merchandises");
	for each row in Object.Items do
		details = ItemsTable[row.LineNumber - 1];
		XML.WriteStartElement("Row");
		writeAttribute("Code", TrimR(details.Code));
		name = Conversion.ValuesToString (
			details.SKU, details.Item, details.Feature, ? ( details.Series = "", "", "#" + details.Series )
		);
		writeAttribute("Name", name, true);
		writeAttribute("UnitOfMeasure", details.Unit, true);
		qty = row.Quantity;
		total = row.Total * rate / factor;
		vat = row.VAT * rate / factor;;
		amount = total - vat;
		writeAttribute("Quantity", qty, true, "NFD=3; NDS=.; NZ=0; NG=");
		writeAttribute("UnitPriceWithoutTVA", amount / qty, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPriceWithoutTVA", amount, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TVA", row.VATRate, true, "NFD=; NDS=.; NZ=0; NG=");
		writeAttribute("TotalTVA", vat, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPrice", total, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("OtherInfo", row.OtherInfo);
		writeAttribute("PackageType", details.Package);
		writeAttribute("NumberOfPlaces", row.QuantityPkg, , "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("GrossWeight", details.Weight * qty, , "NFD=2; NDS=.; NZ=0; NG=");
		XML.WriteEndElement();
	enddo;
	for each row in Object.Services do
		details = ServicesTable[row.LineNumber - 1];
		XML.WriteStartElement("Row");
		writeAttribute("Code", TrimR(details.Code));
		writeAttribute("Name", details.Item, true);
		writeAttribute("UnitOfMeasure", details.Unit, true);
		qty = row.Quantity;
		total = row.Total * rate / factor;;
		vat = row.VAT * rate / factor;;
		amount = total - vat;
		writeAttribute("Quantity", qty, true, "NFD=3; NDS=.; NZ=0; NG=");
		writeAttribute("UnitPriceWithoutTVA", amount / ?(qty = 0, 1, qty), true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPriceWithoutTVA", amount, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TVA", row.VATRate, true, "NFD=; NDS=.; NZ=0; NG=");
		writeAttribute("TotalTVA", vat, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPrice", total, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("OtherInfo", row.OtherInfo);
		XML.WriteEndElement();
	enddo;
	for each row in Object.Discounts do
		details = BenefitsTable[row.LineNumber - 1];
		XML.WriteStartElement("Row");
		writeAttribute("Code", TrimR(details.Code));
		writeAttribute("Name", details.Item, true);
		writeAttribute("UnitOfMeasure", details.Unit, true);
		total = row.Amount * rate / factor;;
		vat = row.VAT * rate / factor;;
		amount = total - vat;
		writeAttribute("Quantity", 0, true, "NFD=3; NDS=.; NZ=0; NG=");
		writeAttribute("UnitPriceWithoutTVA", - amount, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPriceWithoutTVA", - amount, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TVA", row.VATRate, true, "NFD=; NDS=.; NZ=0; NG=");
		writeAttribute("TotalTVA", - vat, true, "NFD=2; NDS=.; NZ=0; NG=");
		writeAttribute("TotalPrice", - total, true, "NFD=2; NDS=.; NZ=0; NG=");
		XML.WriteEndElement();
	enddo;
	XML.WriteEndElement();
	XML.WriteStartElement("CreationMotiv");
	if (Fields.VATPayer) then
		if (Object.Transfer) then
			value = "5";
		else
			value = "4";
		endif;
	else
		if (Object.Transfer) then
			value = "2";
		else
			value = "1";
		endif;
	endif;
	XML.WriteText(value);
	XML.WriteEndElement();
	XML.WriteEndElement();
	XML.WriteEndElement();
	
EndProcedure

Procedure writeAttribute(Name, Value, Mandatory = false, Format = undefined)
	
	if (Mandatory
			or ValueIsFilled(Value)) then
		XML.WriteAttribute(Name, ?(Format = undefined, Value, Format(Value, Format)));
	endif;
	
EndProcedure

Function commit()
	
	Object.Status = Enums.FormStatuses.Waiting;
	try
		Object.Write();
	except
		logError(ErrorDescription());
		return false;
	endtry;
	return true;
	
EndFunction

Procedure logError(Error)
	
	Progress.Put(Error, JobKey, true);
	WriteLogEvent(Metaname, EventLogLevel.Error, Meta, , Error);
	
EndProcedure

Procedure complete()
	
	XML.WriteEndElement();
	XML.Close();
	PutToTempStorage(new BinaryData(TempFile), Parameters.Address);
	DeleteFiles(TempFile);
	
EndProcedure

#endif