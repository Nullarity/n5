Commando ( "e1cib/data/ChartOfCalculationTypes.Compensations" );
With ( "Compensations (cr*" );
value = _.Method;
if ( value <> undefined ) then
	Put ( "#Method", value );
endif;
value = _.Description;
if ( value <> undefined ) then
	Set ( "#Description", value );
endif;
value = _.Code;
if ( value <> undefined ) then
	Set ( "#Code", value );
endif;
value = _.Account;
if ( value <> undefined ) then
	Put ( "#Account", value );
endif;
value = _.Insurance;
if ( value <> undefined ) then
	Set ( "#Insurance", value );
endif;
value = _.Base;
if ( value.Count () > 0 ) then
	Click ( "#FormWrite" );
	for each base in value do
		Click ( "#BaseContextMenuAdd" );
		Put ( "#BaseCalculationType", base );
	enddo;
endif;

Click ( "#FormWriteAndClose" );



