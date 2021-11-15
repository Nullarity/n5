// Fill compensations list

Connect ();
CloseAll ();

list = new Array ();
list.Add ( new Structure ( "Method, Description", "Hourly Rate", "Часовой тариф" ) );
list.Add ( new Structure ( "Method, Description", "Monthly Rate", "Оклад" ) );
list.Add ( new Structure ( "Method, Description", "Fixed Amount", "Фиксированная сумма" ) );
list.Add ( new Structure ( "Method, Description", "Vacation", "Отпускные" ) );

for each item in list do
	Commando ( "e1cib/data/ChartOfCalculationTypes.Compensations" );
	With ( "Compensations (cr*" );
	Put ( "#Method", item.Method );
	Set ( "#Description", item.Description );
	Click ( "#TaxesMarkAll" );
	Click ( "#FormWriteAndClose" );
enddo;

