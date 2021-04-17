Call ( "Common.Init" );
CloseAll ();

StandardProcessing = false;

MainWindow.ExecuteCommand ( "e1cib/list/ChartOfCharacteristicTypes.Dimensions" );

fill ( "Addresses", "Адреса", "Adrese" );
fill ( "Bank Accounts", "Банковские счета", "Conturi bancare" );
fill ( "Cash Flows", "Статьи ДДС", "Fluxuri de fonduri" );
fill ( "Contracts", "Договора", "Contracte" );
fill ( "Departments", "Подразделения", "Subdiviziuni" );
fill ( "Employees", "Сотрудники", "Angajați" );
fill ( "Expenses", "Затраты", "Cheltuieli" );
fill ( "Fixed assets", "Основные средства", "Imobilizări corporale" );
fill ( "Intangible Assets", "Нематериальные активы", "Imobilizări necorporale" );
fill ( "Items", "Товары", "Mărfuri" );
fill ( "Organizations", "Организации", "Terți" );
fill ( "Payment Locations", "Места оплаты", "Locurile de plată" );
fill ( "Warehouses", "Склады", "Depozite" );
fill ( "Assets Categories", "Категории ОС", "Grup de impozitare" );
fill ( "Taxes", "Налоги и отчисления", "Impozite și deduceri" );
fill ( "Income Tax Codes", "Коды выплат ПН", "Codurile privind impozitul pe venit" );
fill ( "Compensations", "Начисления", "Calcule" );


Procedure fill ( Description, DescriptionRu, DescriptionRo )

	With ( "Account Dimensions" );
	if ( not GotoRow ( "#List", "Description", Description, false ) ) then
		GotoRow ( "#List", "Description", Description, true );
	endif;
	Click ( "#FormChange" );
	With ( "*(Account Dimensions)" );
	try
		Check ( "#Description", Description );
		Put ( "#DescriptionRu", DescriptionRu );
		Put ( "#Description", DescriptionRo );
		Click ( "#FormWriteAndClose" );
	except
		message ( Description );
	endtry;	

EndProcedure
