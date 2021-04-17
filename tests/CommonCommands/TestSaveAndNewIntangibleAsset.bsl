Commando ( "e1cib/list/Catalog.IntangibleAssets" );
With ( "Intangible Assets" );
p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = _.IntangibleAsset;
Call ( "Common.Find", p );
Click ( "#FormChange" );
With ( "*(Intangible Assets)" );
Click ( "#FormCommonCommandSaveAndNew" );
With ( "Intangible Assets (create)" );

CloseAll ();
