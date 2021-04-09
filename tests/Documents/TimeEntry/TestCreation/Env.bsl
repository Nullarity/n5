//
// Metadata
//
__.Insert ( "Projects", Call ( "Catalogs.Projects.TestCreation.GetTypes" ) );
//
// Test Context
//
__.Insert ( "MyCompany", __.Company );
__.Insert ( "TestCustomer", "Test Customer" );

__.Insert ( "CurrentCustomer" );
__.Insert ( "CurrentProject" );
__.Insert ( "CurrentProjectType" );
__.Insert ( "Form" );