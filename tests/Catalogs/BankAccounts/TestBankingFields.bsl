// Create Bank Account and check Banking Application field behaviour

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Catalog.BankAccounts.Create");

With ( "Bank Accounts (create)" );
CheckState ( "#Application, #Unloading", "Visible", false );

Choose ( "#Owner" );

With ( "Select data type" );
Click ( "#OK" );

With ();
Set ( "#Owner", "ABC Distributions" );

CheckState ( "#Application, #Unloading", "Visible" );

Disconnect ();