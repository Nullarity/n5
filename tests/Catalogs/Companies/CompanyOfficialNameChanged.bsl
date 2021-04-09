// - Create a new Company
// - Create a new Organization & check company's inheritance

Call ( "Common.Init" );
CloseAll ();

// Create a new Company
Commando ( "e1cib/data/Catalog.Companies" );
form = With ( "Companies (cr*" );

name = Call ( "Common.GetID" );
Set ( "#Description", name );
Click ( "#FormWrite" );

// Create addresses
field = Activate ( "#PaymentAddress" );
field.Create ();
With ( "Addresses (cr*" );
Click ( "#Manual" );
address = "Address " + name;
Set ( "#Address", address );
Click ( "#FormWriteAndClose" );

// Create a new Organization
With ( form );
Click ( "#CreateOrganization" );

// Check if names are ok
With ( "Organizations (cr*" );
Check ( "#Description", name );
Click ( "#FormWrite" );

// Check addresses inheritance
Check ( "#PaymentAddress", address );
Check ( "#ShippingAddress", address );
