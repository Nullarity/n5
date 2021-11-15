Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/ChartOfCalculationTypes.Taxes" );
form = With ( "Taxes (cr*" );

income = "Income Tax (scale)";
Set ( "#Method", income );
Put ( "#Description", income + Call ( "Common.GetID" ) );
Set ( "#Account", "5333" );
Set ( "#Code", Call ( "Common.GetID" ) );

Click ( "#Write" );

// Create a new Rate
Click ( "#PayrollTaxesCreate" );
With ( "Payroll Taxes (cr*" );
Set ( "#Limit", "500" );
Set ( "#Rate", "5" );
Click ( "#FormWriteAndClose" );

// Cancel this Rate
With ( form );
Click ( "#PayrollTaxesChange" );
rateForm = With ( "Payroll Taxes*" );

Click ( "#InformationRegisterPayrollTaxesCancel" );
With ( "Payroll Taxes (cr*" );
nextMonth = AddMonth ( CurrentDate (), 1 );
Set ( "#Period", Format ( nextMonth, "DF='MM/yyyy'" ) );
Click ( "#FormWriteAndClose" );
Close ( rateForm );

// Create another rate
Click ( "#PayrollTaxesCreate", form );
With ( "Payroll Taxes (cr*" );
Set ( "#Limit", "1000" );
Set ( "#Rate", "8" );
Click ( "#FormWriteAndClose" );

// Cancel another rate from context menu
With ( form );
Click ( "#PayrollTaxesCancel" );

With ( "Payroll Taxes (cr*" );
nextMonth = AddMonth ( CurrentDate (), 1 );
Set ( "#Period", Format ( nextMonth, "DF='MM/yyyy'" ) );
Click ( "#FormWriteAndClose" );

// Click to Actual rates and come back
With ( form );
Click ( "#PayrollTaxesShowActual" );
Click ( "#ActualRatesShowRecords" );
