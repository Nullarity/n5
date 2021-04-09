// Description:
// Set filters in Payemnt order list form and create a new Payment order.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "2B8A8C66" );

form = Call ( "Common.OpenList", Meta.Documents.PaymentOrder );

Choose ( "#BankAccount" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.BankAccounts;
p.CreateScenario = "Catalogs.BankAccounts.Create";
p.Search = "BankAccount " + id;

Call ( "Common.Select", p );

With ( form );
account = "Account " + id;

With ( form );
Choose ( "#Recipient" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateVendor";
p.Search = "Vendor " + id;
Call ( "Common.Select", p );

With ( form );
recipient = Fetch ( "#Recipient" );

Click ( "#FormCreate" );

With ( "Payment order (create)" );
//Check ( "#BankAccount", account );
Check ( "#Recipient", recipient );

