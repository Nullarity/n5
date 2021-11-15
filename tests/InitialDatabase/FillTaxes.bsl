StandardProcessing = false;

MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Taxes" );

// ro на будущее может понадобится
//fill ( "Taxă pentru amenajarea teritoriului" );
//fill ( "Taxă de organizare a licitaţiilor şi loteriilor pe teritoriul unităţii administrativ-teritoriale" );
//fill ( "Taxă de plasare (amplasare) a publicitatii (reclamei)" );
//fill ( "Taxă de aplicare a simbolicii locale" );
//fill ( "Taxă pentru unităţiie comerciale şi/sau de prestări servicii" );
//fill ( "Taxă de piaţă" );
//fill ( "Taxă pentru cazare" );
//fill ( "Taxă balneară" );
//fill ( "Taxă pentru prestarea serviciilor de transport auto de călători pe teritoriul municipiilor" );
//fill ( "Taxă pentru parcare" );
//fill ( "Taxă de la posesorii de câini" );
//fill ( "Taxă pentru parcaj" );
//fill ( "Taxă pentru salubrizare" );
//fill ( "Taxă pentru dispozitivele publicitare" );
//fill ( "Taxă rutieră" );
//fill ( "Taxa funciara" );

fill ( "Дорожный сбор" );
fill ( "Курортный сбор" );
fill ( "Рыночный сбор" );
fill ( "Сбор за благоустройство территории" );
fill ( "Сбор за временное проживание" );
fill ( "Сбор за землю" );
fill ( "Сбор за использование местной символики" );
fill ( "Сбор за объекты торговли и/или объекты по оказанию услуг" );
fill ( "Сбор за организацию аукционов и лотерей в пределах административно территориальной единицы" );
fill ( "Сбор за парковку" );
fill ( "Сбор за парковку автотранспорта" );
fill ( "Сбор за предоставлеие услуг по автомобильной перевозке пассажиров на территории муниципиев" );
fill ( "Сбор за размещение рекламы" );
fill ( "Сбор за рекламные устройства" );
fill ( "Сбор за санитарную чистку" );
fill ( "Сбор с владельцев собак" );


Procedure fill ( Description )

	With ( "Taxes" );
	Click ( "#FormCreate" );
	With ( "Taxes (create)" );
	Put ( "#Description", Description );
	Click ( "#FormWriteAndClose" );

EndProcedure	