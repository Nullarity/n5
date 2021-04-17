Call ( "Common.Init" );
CloseAll ();

list = Call ( "Common.OpenList", Meta.InformationRegisters.Tracking );

Choose ( "#PeriodFilter" );
With ( "Select period" );

Set ( "#DateBegin", Format ( Date ( 2016, 1, 1 ), "DLF=D" ) );
Set ( "#DateEnd", Format ( Date ( 2016, 1, 31 ), "DLF=D" ) );

Click ( "#Select" );

With ( list );

Clear ( "#Zoom" );

Clear ( "#PeriodFilter" );

Clear ( "#Zoom" );
