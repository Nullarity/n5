Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "258D5BC9#" );
Run ( "CreateEnv", id );

Call ( "Common.OpenList", Meta.Documents.AssetsTransfer );

p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = id;
Call ( "Common.Find", p );
form = With ( "Assets Transfers" );

Click ( "#FormDataProcessorMF1MF1" );
With ( "Form MF-1: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
