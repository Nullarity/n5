Call ( "Common.Init" );

CloseAll ();

office = "_Office: " + CurrentDate ();
branch = "_Branch: " + CurrentDate ();

Call ( "Common.OpenList", Meta.Catalogs.PaymentLocations );

p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.PaymentLocations;
p.Choose = false;
p.Search = office;
Call ( "Common.Select", p );

Call ( "Common.OpenList", Meta.Catalogs.PaymentLocations );

p = Call ( "Common.Select.Params" );
p.Object = Meta.Catalogs.PaymentLocations;
p.Choose = false;
p.Search = branch;
Call ( "Common.Select", p );

Call ( "Common.OpenList", Meta.Documents.CashTransfer );

Click ( "#FormCreate" );
form = With ( "Cash Transfer (create)" );

With ( form );

Set ( "Sender", office );
Set ( "#Account", "2411" );
Set ( "Receiver", branch );
Set ( "#AccountTo", "2411" );
Set ( "Amount", "1500" );

Click ( "Post" );
Click ( "#FormReportRecordsShow" );
With ( "Records: Cash Transfer *" );
Call ( "Common.CheckLogic", "#TabDoc" );
