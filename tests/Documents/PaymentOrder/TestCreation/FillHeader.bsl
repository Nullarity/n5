form = __.Form;
With ( form );

Set ( "Company", __.MainCompany );
Put ( "#BankAccount", "BankAccount" );
With ( form );
Choose ( "#Recipient" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
p.Search = "_test Organization " + __.Today;
Call ( "Common.Select", p );

With ( form );
Choose ( "#CashFlow" );
Call ( "Select.CashFlow", "_test CashFlow " + __.Today );

With ( form );
Set ( "#Amount", 100 );

Set ( "#VatRate", "20%" );
//Set ( "#VAT", 20 );
Set ( "#IncomeTaxRate", 5 );
//Set ( "#IncomeTax", 5 );

//Activate ( "#GroupPrint" );
Set ( "#PaymentContent", "Test payment content..." );
Choose ( "#PaymentContent" );
Call ( "Select.ContentTemplates", "_test Template " + __.Today );
