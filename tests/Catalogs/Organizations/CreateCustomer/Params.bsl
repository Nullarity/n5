p = new Structure ();
p.Insert ( "Description", "_Customer: " + CurrentDate () );
p.Insert ( "Government", false );
p.Insert ( "CodeFiscal" );
p.Insert ( "Currency", __.LocalCurrency );
p.Insert ( "BankAccount" );
p.Insert ( "PaymentAddress" );
p.Insert ( "RateType" );
p.Insert ( "Rate" );
p.Insert ( "Delivery", 0 );
p.Insert ( "Terms" );
p.Insert ( "ClearTerms", false );
p.Insert ( "TaxGroup" );
p.Insert ( "TaxGroupCreationParams" );
p.Insert ( "CloseAdvances", true );
p.Insert ( "Items", new Array () ); // Array of Catalogs.Organizations.CreateCustomer.ContractItem
p.Insert ( "Services", new Array () ); // Array of Catalogs.Organizations.CreateCustomer.ContractService
p.Insert ( "SkipAddress", false );
p.Insert ( "ContractSigned", false );
p.Insert ( "ContractDateStart", undefined );
p.Insert ( "ContractDateEnd", undefined );
return p;