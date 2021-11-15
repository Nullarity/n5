Run ( "Env" );

//
// Test My company, project type
//

__.CurrentPricing = __.Pricing.HourlyRate;
__.CurrentCustomer = __.MyCompany;

__.CurrentProjectType = __.Projects.Regular;
Run ( "Create" );

__.CurrentProjectType = __.Projects.Vacation;
Run ( "Create" );

__.CurrentProjectType = __.Projects.SickDay;
Run ( "Create" );

__.CurrentProjectType = __.Projects.Holiday;
Run ( "Create" );

//
// Test Customer, pricing
//

__.CurrentCustomer = __.TestCustomer;
__.CurrentProjectType = __.Projects.Regular;

__.CurrentPricing = __.Pricing.Amount;
Run ( "Create" );

__.CurrentPricing = __.Pricing.HourlyRate;
Run ( "Create" );

__.CurrentPricing = __.Pricing.EmployeeRate;
Run ( "Create" );

__.CurrentPricing = __.Pricing.TaskRate;
Run ( "Create" );