if ( Call ( "Common.AppIsCont" ) ) then
	p = Call ( "Catalogs.BanksClassifier.Create.Params" );
	p.Code = _.Code;
	p.Description = _.Description;
	Call ( "Catalogs.BanksClassifier.Create", p );
	
	form = Call ( "Common.OpenList", Meta.Catalogs.Banks );
	
	Click ( "#FormCreate" );
	With ( "Banks Classifier" );
	
	p = Call ( "Common.Find.Params" );
	p.Where = "Code";
	p.What = _.Code;
	Call ( "Common.Find", p );
	
	Click ( "#FormSelect" );
	
	Close ( form );
else
	Commando ( "e1cib/data/Catalog.Banks" );
	With ( "Banks (create)" );
	Put ( "#Description", _.Description );
	Put ( "#Code", _.Code );
	Click ( "#FormWriteAndClose" );
endif;

