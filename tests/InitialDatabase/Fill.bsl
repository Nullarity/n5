// Fill Initial Database.
// Before start the scenario make sure that:
// - Your database was created in empty folder and attached to repo. Therefore, data is completely clean
// - Running session user's language should be English
// - Make sure that your session is running in TestClient mode. Please, check testing port as well

Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/data/Catalog.Tenants" );
With ( "Tenants (cr*" );
Set ( "#Code", "0123456789" );
Set ( "#Description", "Начальный образ" );
Click ( "#FormWrite" );
Click ( "#FormCatalogTenantsActivate" );

Run ( "FillMetadata" );
Run ( "FillAccess" );
Run ( "FillCurrencies" );
Run ( "FillUnits" );
Run ( "FillCountries" );
Run ( "CreateCompanyAndAdministrator" );

Disconnect ( true );
DoMessageBox ( "Please, run your application again with tenant=0123456789. Close this window after starting application again" );
Connect ();

Run ( "FillSystemVisibility" );
Run ( "FillAccounts" );

Run ( "FillDimensions" );
Run ( "CreateGeneralData" );
Run ( "FillTerms" );
Run ( "CreateSchedule" );
Run ( "FillInsurance" );
settings = getSettings ();
Run ( "TranslateSettings", settings );
Run ( "FillVAT" );
Run ( "FillApplicationSettings", settings );
Run ( "FillTaxes" );
Run ( "FillBanks" );
Run ( "FillAssetsTypes" );
Run ( "FillCustomsCharges" );
Run ( "FillPayrollTaxes" );
Run ( "FillCompensations" );
Run ( "FillDeductions" );
Call ( "InitialDatabase.RegulatoryReports.FillRegulatoryReports" );
Run ( "SetUsersRights" );
Run ( "FillCashFlows" );
Run ( "CreatePhoneTemplates" );
Run ( "FillSalutationsGender" );

Function getSettings ()

	map = new Map ();
	map.Insert ( "Employees Other Debt", "Прочая задолженность" );
	map.Insert ( "Employees", "Сотрудники" );
	map.Insert ( "Deposit Liabilities", "Обязательства депонентам" );
	map.Insert ( "Employer Other Debt", "Предстоящие обязательства" );
	map.Insert ( "Expense Report Account", "Задолженность подотчетных лиц" );
	map.Insert ( "Payroll Account", "Обязательства по оплате труда" );
	map.Insert ( "Insurance", "Страхование" );
	
	//vacation 
	map.Insert ( "Extended Vacation", "Лицо,продлившее  годовой отпуск" );
	map.Insert ( "Vacation Without Pay", "Лицо, находящееся в неоплачиваемом отпуске (за свой счет)" );
	map.Insert ( "Paternity Vacation", "Лицо, находящееся в отпуске по отцовству" );
	map.Insert ( "Regular Vacation", "Лицо, находящееся в очередном оплачиваемом отпуске" );

	// sick days	
	map.Insert ( "Extra Child Care", "Лицо, находящееся в дополнительном неоплачиваемом отпуске по уходу за ребенком с 3 до 6 лет" );
	map.Insert ( "Child Care", "Лицо, находящееся в отпуске по уходу за ребенком" );
	map.Insert ( "Regular Sick Leave", "Лицо, получившее пособие  по медицинскому отпуску, работодатель" );
	map.Insert ( "Sick Days, Social", "Лицо, получившее пособие  по медицинскому отпуску, БГСС" );
	map.Insert ( "Sick Days, Production", 			"Лицо, получившее пособие по временной нетрудоспособности, травма на производстве, работодатель" );
	map.Insert ( "Sick Days, Production Social", 	"Лицо, получившее пособие по временной нетрудоспособности, травма на производстве, БГСС" );
	map.Insert ( "Sick Days, Child", 				"Лицо, получившее пособие по уходу за больным ребенком" );
	map.Insert ( "Sick Days, Only Social", 			"Лицо, получившее пособие по временной нетрудоспособности, выплаченное с первого дня из средств БГСС" );
	
	map.Insert ( "LVI", "МБП" );
	map.Insert ( "LVI Limit", "Предел стоимости МБП" );
	map.Insert ( "LVI Amortization Account", "Счет износа МБП" );
	map.Insert ( "LVI Exploitation Account", "Счет МБП в эксплуатации" );
	
	map.Insert ( "Closing Advances", "Закрытие полученных авансов" );
	map.Insert ( "Receivables from VAT Account", "Счет задолженности по НДС" );
	map.Insert ( "VAT from Advance", "НДС с авансов" );
	map.Insert ( "VAT on Export", "НДС при экспорте" );
	map.Insert ( "Expense Report Debt", "Обязательства подотчетным лицам" );
	
	return map;
	
EndFunction
