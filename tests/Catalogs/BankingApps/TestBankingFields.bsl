// Create Bank Account and check Banking Application field behaviour

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.BankingApps.Create");
Set ( "#Application", "Eximbank" );
Next ();