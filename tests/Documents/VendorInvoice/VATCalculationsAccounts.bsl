
Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Document.VendorInvoice" );
With ( "Vendor Invoice (cr*" );

table = Get ( "#Accounts" );
Click ( "#AccountsAdd" );

Put ( "#AccountsAccount", "5212" );
Put ( "#AccountsCurrency", "CAD" );
Put ( "#AccountsRate", "10" );
Put ( "#AccountsCurrencyAmount", "10" );
Next ();

// Calc without VAT
Check ( "#AccountsAmount", 100, table );

// Set VAT use = Included in Price
Put ( "#VATUse", "Included in Price" );
Set ( "#AccountsVATCode", "20%", table );
Check ( "#AccountsVAT", 16.67, table );
Check ( "#VAT", 16.67 );

// Set VAT use = Excluded from Price
Put ( "#VATUse", "Excluded from Price" );
Check ( "#AccountsVAT", 20, table );
Check ( "#VAT", 20 );
Check ( "#Amount", 120 );

Set ( "#AccountsAmount", 200, table );
Check ( "#VAT", 40 );
Check ( "#Amount", 240 );

Set ( "#AccountsCurrencyAmount", "5", table );
Check ( "#VAT", 10 );
Check ( "#Amount", 60 );

