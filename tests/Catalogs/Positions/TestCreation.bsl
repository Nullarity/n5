// creates an item of Catalog "Positions" from Catalog "PositionsClassifier"
//
// Open list form of catalog Positions
// pressing "Create" button
// choosing line with code 4810
// look if an item with code 4810 was created

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/Catalog.Positions" );
With ( "Positions" );
Click ( "#FormCreate" );
With ( "Positions Classifier" );
p = Call ( "Common.Find.Params" );
p.Where = "Position Code";
p.What = "4810";
Call ( "Common.Find", p );
Click ( "#FormChoose" );

With ( "Positions" );
p = Call ( "Common.Find.Params" );
p.Where = "Position Code";
p.What = "4810";
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Positions)" );