form = __.Form;
pricing = __.Pricing;
projects = __.Projects;
currentPricing = __.CurrentPricing;
projectType = __.CurrentProjectType;

//page = Activate ( "Tasks", form, "Group" );
//With ( page );

if ( projectType = projects.Regular ) then
	Click ( "Strong tasks control", , "Field" );
endif;

table = Activate ( "#Tasks" );
commands = table.GetCommandBar ();

Call ( "Table.AddEscape", table );

Click ( "Add", commands );

Choose ( "Performer", table );

performerName = "_Performer " + CurrentDate ();
p = Call ( "Catalogs.Employees.Create.Params" );
p.Description = performerName;
Call ( "Catalogs.Employees.Create", p );
Call ( "Select.Employee", performerName );

if ( projectType = projects.Regular ) then
	Choose ( "Task", table );
	Call ( "Select.Task", "Installation" );
endif;

Set ( "Description", "Some work", table );

hours = 3;
if ( projectType = projects.Regular ) then
	if ( currentPricing = pricing.Amount ) then
	elsif ( currentPricing = pricing.HourlyRate ) then
		rate = Number ( Fetch ( "#HourlyRate" ) );
		Set ( "#TasksDuration", hours, table );
	elsif ( currentPricing = pricing.EmployeeRate
		or currentPricing = pricing.TaskRate ) then
		rate = 65;
		Set ( "#TasksHourlyRate", rate, table );
		Set ( "#TasksDuration", hours, table );
	endif;

	table.EndEditRow ();

	if ( currentPricing <> pricing.Amount ) then
		amount = hours * rate;
		Check ( "Amount", amount, table );
		Check ( "#Amount", amount, form );
	endif;
else
	table.EndEditRow ();
endif;

Call ( "Table.CopyEscapeDelete", table );

if ( projectType = projects.Regular ) then
	if ( currentPricing <> pricing.Amount ) then
		amount = hours * rate;
		Check ( "Amount", amount, table );
		Check ( "#Amount", amount, form );
	endif;
endif;