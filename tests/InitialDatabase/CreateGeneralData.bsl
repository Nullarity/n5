// Create Company, Warehouse, Department and other defaults

company = "Наша компания";
department = "Администрация";
warehouse = "Основной";
prices = "Закупочные";
paymentLocation = "Центральный офис";

// ******************
// Create Prices
// ******************

Commando ( "e1cib/command/Catalog.Prices.Create" );
With ( "Prices (cr*" );
Put ( "#Owner", company );
Set ( "#Description", prices );
Put ( "#Pricing", "Base" );
Put ( "#Currency", "MDL" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/list/Catalog.Companies" );
With ( "Companies" );
Click ( "#FormChange" );
With ( "Наша компания *" );
Put ( "#CostPrices", prices );
Click ( "#FormWriteAndClose" );

// ***********************
// Translate Contact Types
// ***********************

Commando ( "e1cib/list/Catalog.ContactTypes" );
set = new Array ();
set.Add ( new Structure ( "En, Ru", "Accountant", "Бухгалтер" ) );
set.Add ( new Structure ( "En, Ru", "Administrator", "Администратор" ) );
set.Add ( new Structure ( "En, Ru", "Director", "Директор" ) );
set.Add ( new Structure ( "En, Ru", "Manager", "Менеджер" ) );

for each item in set do
	name = item.En;
	With ( "Contact Types" );
	GotoRow ( "#List", "Description", name );
	Click ( "#FormChange" );
	With ( name + " *" );
	Set ( "#Description", item.Ru );
	Click ( "#FormWriteAndClose" );
enddo;

// ******************
// Create Warehouse
// ******************

Commando ( "e1cib/command/Catalog.Warehouses.Create" );
With ( "Warehouses (cr*" );
Put ( "#Owner", company );
Put ( "#Description", warehouse );
Click ( "#FormWriteAndClose" );

// ******************
// Create Department
// ******************

Commando ( "e1cib/command/Catalog.Departments.Create" );
With ( "Departments (cr*" );
Put ( "#Owner", company );
Put ( "#Description", department );
Click ( "#FormWriteAndClose" );

// ***********************
// Create Payment Location
// ***********************

Commando ( "e1cib/command/Catalog.PaymentLocations.Create" );
With ( "Payment Locations (cr*" );
Put ( "#Owner", company );
Put ( "#Description", paymentLocation );
Click ( "#FormWriteAndClose" );

// *************************
// Create Expenses
// *************************

expenses = "Заработная плата";
Call ( "Catalogs.Expenses.Create", expenses );
p = Call ( "Catalogs.ExpenseMethods.Create.Params" );
p.Description = expenses;
p.Expense = expenses;
p.Account = "7131";
Call ( "Catalogs.ExpenseMethods.Create", p );

// ***********************
// Create Cash Operations
// ***********************

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Cash Expense" );
Put ( "#Description", "Расход из кассы (прочее)" );
Put ( "#AccountCr", "2411" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Cash Expense" );
Put ( "#Description", "Расход из кассы, валюта (прочее)" );
Put ( "#AccountCr", "2412" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Cash Receipt" );
Put ( "#Description", "Приход в кассу (прочее)" );
Put ( "#AccountDr", "2411" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Cash Receipt" );
Put ( "#Description", "Приход в кассу, валюта (прочее)" );
Put ( "#AccountDr", "2412" );
Click ( "#FormWriteAndClose" );

// ***********************
// Create Bank Operations
// ***********************

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Bank Expense" );
Put ( "#Description", "Расход с Р/С  (прочее)" );
Put ( "#AccountCr", "2421" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Bank Expense" );
Put ( "#Description", "Расход с Р/С , валюта (прочее)" );
Put ( "#AccountCr", "2431" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Bank Receipt" );
Put ( "#Description", "Поступление на Р/С (прочее)" );
Put ( "#AccountDr", "2421" );
Click ( "#FormWriteAndClose" );

Commando ( "e1cib/command/Catalog.Operations.Create" );
With ( "Operations (cr*" );
Put ( "#Operation", "Bank Receipt" );
Put ( "#Description", "Поступление на Р/С, валюта (прочее)" );
Put ( "#AccountDr", "2431" );
Click ( "#FormWriteAndClose" );

// *********************
// Organization Accounts
// *********************

Commando ( "e1cib/data/InformationRegister.OrganizationAccounts" );
With ( "Organizations (cr*" );
Put ( "#CustomerAccount", "2211" );
Put ( "#VendorAccount", "5211" );
Put ( "#AdvanceGiven", "2241" );
Put ( "#AdvanceTaken", "5231" );
Click ( "#FormWriteAndClose" );

// *********************
// Item Accounts
// *********************

Commando ( "e1cib/data/InformationRegister.ItemAccounts" );
With ( "Items (cr*" );
Put ( "#Account", "2171" );
Put ( "#Income", "6113" );
Put ( "#SalesCost", "7112" );
Put ( "#VAT", "5344" );
Click ( "#FormWriteAndClose" );

// *********************
// Fixed Asset Accounts
// *********************

Commando ( "e1cib/data/InformationRegister.FixedAssetAccounts" );
With ( "Fixed Assets (cr*" );
Put ( "#Account", "1231" );
Put ( "#Depreciation", "1241" );
Put ( "#Income", "6121" );
Put ( "#VAT", "5344" );
Click ( "#FormWriteAndClose" );

// *************************
// Intangible Asset Accounts
// *************************

Commando ( "e1cib/data/InformationRegister.IntangibleAssetAccounts" );
With ( "Intangible Assets (cr*" );
Put ( "#Account", "1121" );
Put ( "#Amortization", "1131" );
Put ( "#Income", "6121" );
Put ( "#VAT", "5344" );
Click ( "#FormWriteAndClose" );
