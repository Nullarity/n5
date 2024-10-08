﻿p = new Structure ();
p.Insert ( "Description" );
p.Insert ( "Year", Format ( Year ( CurrentDate () ), "NG=" ) ); // can be array of years
p.Insert ( "AverageDays", "21.10" );
p.Insert ( "TimesheetPeriod", "Month" );
p.Insert ( "Holidays" );
p.Insert ( "Monday", 8 );
p.Insert ( "MondayEvening", 0 );
p.Insert ( "MondayNight", 0 );
p.Insert ( "Tuesday", 8 );
p.Insert ( "TuesdayEvening", 0 );
p.Insert ( "TuesdayNight", 0 );
p.Insert ( "Wednesday", 8 );
p.Insert ( "WednesdayEvening", 0 );
p.Insert ( "WednesdayNight", 0 );
p.Insert ( "Thursday", 8 );
p.Insert ( "ThursdayEvening", 0 );
p.Insert ( "ThursdayNight", 0 );
p.Insert ( "Friday", 8 );
p.Insert ( "FridayEvening", 0 );
p.Insert ( "FridayNight", 0 );
p.Insert ( "Saturday", 0 );
p.Insert ( "SaturdayEvening", 0 );
p.Insert ( "SaturdayNight", 0 );
p.Insert ( "Sunday", 0 );
p.Insert ( "SundayEvening", 0 );
p.Insert ( "SundayNight", 0 );
p.Insert ( "Overtime", true );
p.Insert ( "OvertimeRate1", 1.5 );
p.Insert ( "OvertimeLimit", 4 );
p.Insert ( "OvertimeRate2", 2 );
p.Insert ( "DaysOffCoef", 2 );

return p;
