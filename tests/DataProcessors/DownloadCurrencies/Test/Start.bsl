StandardProcessing = false;
Call ( "Common.Init" );
Call ( "Catalogs.Currencies.Create", "USD" );
CloseAll ();

MainWindow.ExecuteCommand ( "e1cib/app/DataProcessor.DownloadCurrencies" );
With ( "Download Currencies" );

Run ( "TestTomorowError" );
Run ( "SetTodayPeriod" );
Run ( "TestEmptyList" );

MainWindow.ExecuteCommand ( "e1cib/app/DataProcessor.DownloadCurrencies" );
form = With ( "Download Currencies" );
table = Activate ( "#List" );
Click ( "#ListMarkAll" );
Click ( "#FormDownload" );

