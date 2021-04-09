// Creates a new Operation
//
// Parameters:
// Catalogs.Schedules.WorkHours.Params

Commando ( "e1cib/data/Catalog.Operations" );
With ( "Operations (cr*" );

value = _.Operation;
if ( value <> undefined ) then
	Set ( "#Operation", value );
endif;

Set ( "#Description", _.Description );

value = _.Simple;
if ( value <> undefined ) then
	flag = Fetch ( "#Simple" );
	click = ( flag = "Yes" and not value ) or ( flag = "No" and value );
	if ( click ) then
		Click ( "#Simple" );
	endif;
endif;

value = _.AccountDr;
if ( value <> undefined ) then
	Set ( "#AccountDr", value );
endif;

value = _.AccountCr;
if ( value <> undefined ) then
	Set ( "#AccountCr", value );
endif;

Click ( "#FormWriteAndClose" );