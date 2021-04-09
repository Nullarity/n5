Call ( "Common.Init" );
CloseAll ();

id = Call ( "Common.ScenarioID", "272B36D5#" );
Call ( "Documents.IntangibleAssetsInventory.TestCreation.Create", id );
Run ( "WriteOffBaseOnLogic", id );
