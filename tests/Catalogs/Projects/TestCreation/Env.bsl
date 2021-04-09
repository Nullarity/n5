Call ( "Common.Init" );
//
// Metadata
//
pricing = new Structure ();
pricing.Insert ( "Amount", "Amount" );
pricing.Insert ( "HourlyRate", "Hourly Rate" );
pricing.Insert ( "EmployeeRate", "Employee Rate" );
pricing.Insert ( "TaskRate", "Task Rate" );

__.Insert ( "Pricing", pricing );
__.Insert ( "Projects", Run ( "GetTypes" ) );
//
// Test Context
//
__.Insert ( "CurrentProjectType" );
__.Insert ( "CurrentPricing" );

__.Insert ( "MyCompany", __.Company );
__.Insert ( "TestCustomer", "Test Customer" );
__.Insert ( "CurrentCustomer" );

__.Insert ( "Form" );