Commando ( "e1cib/list/Catalog.FixedAssets" );
With ( "Fixed Assets" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.FixedAsset;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Fixed Assets)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Fixed Assets (create)" );

CloseAll ();

