// Description:
// Set filters in Transfers list form and create a new Transfer.
// Checks the automatic header filling process
//
// Conditions:
// Command interface shoud be visible.

Call ( "Common.Init" );
CloseAll ();
form = Call ( "Common.OpenList", Meta.Documents.Transfer );

Choose ( "#SenderFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "Main";
Call ( "Common.Select", p );

With ( form );
sender = Fetch ( "#SenderFilter" );

Choose ( "#ReceiverFilter" );
p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.Warehouses;
p.Search = "_Branch";
Call ( "Common.Select", p );

With ( form );
receiver = Fetch ( "#ReceiverFilter" );

Click ( "#FormCreate" );

With ( "Transfer (create)" );
Check ( "#Sender", sender );
Check ( "#Receiver", receiver );
