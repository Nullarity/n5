// Description:
// Creates a new Payroll Tax Item
//
// Parameters:
// CalculationTypes.Taxes.Create.Params
//
// Returns:
// Structure ( "Code, Description" )

Commando ( "e1cib/data/ChartOfCalculationTypes.Taxes" );
form = With ( "Taxes (cr*" );
value = _.Method;
if ( value <> undefined ) then
	Put ( "#Method", value );
endif;
value = _.Description;
if ( value <> undefined ) then
	Set ( "#Description", value );
endif;
value = _.Net;
if ( value <> undefined and value ) then
	Click ( "#Net" );
endif;
value = _.Account;
if ( value <> undefined ) then
	Set ( "#Account", value );
endif;

// Base Compensations
for each base in _.Base do
	
	Click ( "#BaseAdd" );
	Choose ( "#BaseCalculationType" );
	With ( "Select data type" );
	GotoRow ( "#TypeTree", "", "Compensations" );
	Click ( "#OK" );
	With ( "Compensations" );
	GotoRow ( "#List", "Description", base );
	Click ( "#FormChoose" );
	With ( form );

enddo;

// Scale
scale = _.Scale;
rateDate = Format ( _.RateDate, "DF=MM/yyyy" );
if ( scale.Count () = 0 ) then
	// Tax Rate
	rate = _.Rate;
	if ( rate <> undefined ) then
		Click ( "#FormWrite" );
		
		Click ( "#PayrollTaxesCreate" );
		With ( "Payroll Taxes (cr*" );
		Set ( "#Period", rateDate );
		Set ( "#Rate", rate );
		Click ( "#FormWriteAndClose" );
		With ( form );
	endif;
else
	Click ( "#FormWrite" );
	for each limit in scale do
		Click ( "#PayrollTaxesCreate" );
		With ( "Payroll Taxes (cr*" );
		Set ( "#Period", rateDate );
		Set ( "#Limit", limit.Limit );
		Set ( "#Rate", limit.Rate );
		Click ( "#FormWriteAndClose" );
		With ( form );
	enddo;
endif;

With ( form );
Click ( "#FormWrite" );

code = Fetch ( "#Code" );
description = Fetch ( "#Description" );

Close ();

return new Structure ( "Code, Description", code, description );
