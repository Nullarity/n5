Commando ( "e1cib/list/Document.IntangibleAssetsWriteOff" );
With ( "Intangible Assets Write Offs" );
p = Call ( "Common.Find.Params" );
p.Where = "Memo";
p.What = _;
Call ( "Common.Find", p );


Click ( "#FormReportRecordsShow" );
With ( "Records: Intangible Assets Write Off *" );
Call ( "Common.CheckLogic", "#TabDoc" );
