form = __.Form;
pricing = __.Pricing;
projects = __.Projects;
currentPricing = __.CurrentPricing;
currentProjectType = __.CurrentProjectType;
myCompany = ( __.CurrentCustomer = __.MyCompany );

With ( form );

name = Run ( "GetName", currentProjectType ) + "_" + CurrentDate ();
Set ( "#Description", name );
Put ( "#Owner", __.CurrentCustomer );
//Choose ( "Customer" );
//Call ( "Select.Organization", __.CurrentCustomer );

//calculation = Get ( "Calculation", form );
//With ( calculation );

start = CurrentDate ();
Set ( "Start date", Format ( start, "DLF=D" ) );
Set ( "End date", Format ( start + 86400*7, "DLF=D" ) );

Put ( "#Currency", "USD" );
//Choose ( "Currency" );
//Call ( "Select.Currency", "USD" );
//With ( calculation );

if ( myCompany ) then // Only for My company user can change project type
	Set ( "Project type", currentProjectType );
endif;

Set ( "Pricing", currentPricing );
form.GotoNextItem ();

if ( currentPricing = pricing.Amount ) then
	Set ( "#HourlyRate", 30 );
	Set ( "Time", 2 );
	Activate ( "Project Amount" );
	Check ( "Project Amount", 60 );
	Set ( "Project Amount", 120 );
	Activate ( "#HourlyRate" );
	Check ( "#HourlyRate", 60 );
	
	CheckState ( "#HourlyRate, Time, Project Amount", "Enable" );
	CheckState ( "Project Amount", "ReadOnly", false );
elsif ( currentPricing = pricing.HourlyRate ) then
	Set ( "#HourlyRate", 30 );
	Activate ( "Project Amount" );
	Check ( "Project Amount", 0 );
	
	CheckState ( "#HourlyRate", "Enable" );
	CheckState ( "Time", "Enable", false );
	CheckState ( "Project Amount", "ReadOnly" );
elsif ( currentPricing = pricing.EmployeeRate ) then
	CheckState ( "#HourlyRate, Time", "Enable", false );
	CheckState ( "Project Amount", "ReadOnly" );
elsif ( currentPricing = pricing.TaskRate ) then
	CheckState ( "#HourlyRate, Time", "Enable", false );
	CheckState ( "Project Amount", "ReadOnly" );
endif;