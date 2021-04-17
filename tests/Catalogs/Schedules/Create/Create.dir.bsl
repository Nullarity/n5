// Description:
// Creates a new Schedule
//
// Returns:
// Structure ( "Code, Description" )

Commando ( "e1cib/data/Catalog.Schedules" );
With ( "Schedules (cr*" );

Set ( "#Description", _.Description );
Set ( "#AverageDays", _.AverageDays );
Pick ( "#TimesheetPeriod", _.TimesheetPeriod );
holidays = _.Holidays;
if ( holidays <> undefined ) then
	Set ( "#Holidays", _.Holidays );
endif;

Pick ( "#UseOvertime", ? ( _.Overtime, "Yes", "No" ) );
if ( _.Overtime ) then
	Set ( "#OvertimeCoef1", _.OvertimeRate1 );
	Set ( "#OvertimeLimit", _.OvertimeLimit );
	Set ( "#OvertimeCoef2", _.OvertimeRate2 );
endif;

Set ( "#DaysOffCoef", _.DaysOffCoef );

table = Activate ( "#Years" );
Set ( "#YearsYear", _.Year, table );
Set ( "#YearsMonday", _.Monday, table );
Set ( "#YearsMondayEvening", _.MondayEvening, table );
Set ( "#YearsMondayNight", _.MondayNight, table );
Set ( "#YearsTuesday", _.Tuesday, table );
Set ( "#YearsTuesdayEvening", _.TuesdayEvening, table );
Set ( "#YearsTuesdayNight", _.TuesdayNight, table );
Set ( "#YearsWednesday", _.Wednesday, table );
Set ( "#YearsWednesdayEvening", _.WednesdayEvening, table );
Set ( "#YearsWednesdayNight", _.WednesdayNight, table );
Set ( "#YearsThursday", _.Thursday, table );
Set ( "#YearsThursdayEvening", _.ThursdayEvening, table );
Set ( "#YearsThursdayNight", _.ThursdayNight, table );
Set ( "#YearsFriday", _.Friday, table );
Set ( "#YearsFridayEvening", _.FridayEvening, table );
Set ( "#YearsFridayNight", _.FridayNight, table );
Set ( "#YearsSaturday", _.Saturday, table );
Set ( "#YearsSaturdayEvening", _.SaturdayEvening, table );
Set ( "#YearsSaturdayNight", _.SaturdayNight, table );
Set ( "#YearsSunday", _.Sunday, table );
Set ( "#YearsSundayEvening", _.SundayEvening, table );
Set ( "#YearsSundayNight", _.SundayNight, table );

Click ( "#FormWrite" );
code = Fetch ( "#Code" );
Close ();
return new Structure ( "Code, Description", code, _.Description );