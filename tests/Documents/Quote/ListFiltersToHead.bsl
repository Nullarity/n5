// Description:
// Set filters in Quotes list form and create a new Quote.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.Quote );

Choose ( "#CustomerFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Organizations;
p.CreateScenario = "Catalogs.Organizations.CreateCustomer";
p.Search = "_Customer";
Call ( "Common.Select", p );

With ( form );
customer = Fetch ( "#CustomerFilter" );

Click ( "#FormCreate" );

With ( "Quote (create)" );
Check ( "#Customer", customer );
