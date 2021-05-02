Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfCalculationTypes.Taxes" );
With ( "Taxes (cr*" );

id = CurrentDate ();

CheckState ( "#PayrollTaxes", "Enable", false );
Set ( "#Description", id );
Set ( "#Account", "5333" );
Click ( "#FormWrite" );
CheckState ( "#PayrollTaxes", "Enable" );
Click ( "#PayrollTaxesCreate" );
With ( "Payroll Taxes (c*" );
Check ( "#Tax", id );
