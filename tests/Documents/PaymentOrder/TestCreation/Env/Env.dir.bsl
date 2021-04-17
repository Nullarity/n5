//
// Metadata
//
__.Insert ( "MainCompany", Call ( "Select.MainCompanyName" ) );
__.Insert ( "Form" );
__.Insert ( "Today", Left ( "" + BegOfDay ( CurrentDate () ), 10 ) );
Run ( "SetBankAccountMainCompany" );

