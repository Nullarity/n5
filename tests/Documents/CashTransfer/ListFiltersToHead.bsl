// Description:
// Set filters in Cash Transfers list form and create a new Cashe Transfer.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.CashTransfer );

Choose ( "#SenderFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.PaymentLocations;
p.Search = "Office";
Call ( "Common.Select", p );

With ( form );
sender = Fetch ( "#SenderFilter" );

Choose ( "#ReceiverFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.PaymentLocations;
p.Search = "Branch";
Call ( "Common.Select", p );

With ( form );
receiver = Fetch ( "#ReceiverFilter" );

Click ( "#FormCreate" );

With ( "Cash Transfer (create)" );
Check ( "#Sender", sender );
Check ( "#Receiver", receiver );
