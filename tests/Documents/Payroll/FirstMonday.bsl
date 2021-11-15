// Description:
// Returns first Monday from passed date
//
// Parameters:
// Start date
//
// Returns:
// Day of Monday

day = _;
for i = 0 to 6 do
	if ( WeekDay ( day ) = 1 ) then
		break;
	endif;
	day = day + 86400;
enddo;

return day;
