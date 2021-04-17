
Call ( "Common.Init" );
CloseAll ();

// ***********************************
// TaxGroup Params
// ***********************************

taxGroup = "Taxes-5-3-1#";
taxGroupParams = Call ( "Catalogs.TaxGroups.Create.Params" );
taxGroupParams.Description = taxGroup;
tax = Call ( "Catalogs.TaxGroups.Create.TaxItem" );
tax.Description = "Tax 5%";
tax.Percent = 5;
taxGroupParams.Taxes.Add ( tax );
tax = Call ( "Catalogs.TaxGroups.Create.TaxItem" );
tax.Description = "Tax 3%";
tax.Percent = 3;
taxGroupParams.Taxes.Add ( tax );
tax = Call ( "Catalogs.TaxGroups.Create.TaxItem" );
tax.Description = "Tax 1%";
tax.Percent = 1;
taxGroupParams.Taxes.Add ( tax );

// ***********************************
// Create Invoice
// ***********************************

date = CurrentDate ();
customer = "_Test taxes: " + date;

p = Call ( "Documents.Invoice.Sale.Params" );
p.Action = "Post";
p.Date = date - 86400;
p.Customer = customer;
p.CustomerTaxGroup = taxGroup;
p.CustomerTaxGroupCreationParams = taxGroupParams;
p.Rate = "0.83";
p.ContractCurrency = "CAD";

invoiceServices = new Array ();
row = Call ( "Documents.Invoice.Sale.ServicesRow" );
row.Item = "_Service1: " + date;
row.Quantity = "1";
row.Price = "100";
invoiceServices.Add ( row );

p.Services = invoiceServices;
form = Call ( "Documents.Invoice.Sale", p );
With ( form );

Click ( "#FormReportRecordsShow" );
With ( "Records: Invoice *" );
Call ( "Common.CheckLogic", "#TabDoc" );
