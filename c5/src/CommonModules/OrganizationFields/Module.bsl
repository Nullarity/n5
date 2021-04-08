&AtServer
Procedure SetVendorAccount ( Object ) export
	
	accounts = AccountsMap.Organization ( Object.Vendor, Object.Company, "VendorAccount" );
	if ( ValueIsFilled ( accounts.VendorAccount ) ) then
		Object.VendorAccount = accounts.VendorAccount;
	endif; 
	
EndProcedure

&AtServer
Procedure SetCustomerAccount ( Object ) export
	
	accounts = AccountsMap.Organization ( Object.Customer, Object.Company, "CustomerAccount" );
	if ( ValueIsFilled ( accounts.CustomerAccount ) ) then
		Object.CustomerAccount = accounts.CustomerAccount;
	endif;
	
EndProcedure

&AtServer
Procedure SetVendorContract ( Object ) export

	fields = DF.Values ( Object.Vendor, "VendorContract, VendorContract.Company" );
	if ( fields.VendorContractCompany = Object.Company ) then
		if ( not fields.VendorContract.IsEmpty () ) then
			Object.Contract = fields.VendorContract;
		endif; 
	else
		Object.Contract = Catalogs.Contracts.EmptyRef ();
	endif; 
	
EndProcedure

&AtServer
Procedure SetCurrency ( Form ) export

	object = Form.Object;
	fields = DF.Pick ( object.Contract, "Currency" );
	Form.ContractCurrency = fields.Currency;
	data = CurrenciesSrv.Get ( fields.Currency, object.Date );
	object.Currency = fields.Currency;
	object.Rate = data.Rate;
	object.Factor = data.Factor;
	
EndProcedure

&AtServer
Procedure SetVendorImportCurrencyManagerVATMode ( Form ) export

	object = Form.Object;
	fields = "Currency, SupplyManager, VATMode, Import";
	data = DF.Values ( object.Contract, fields );
	object.Currency = data.Currency;
	object.Manager = data.SupplyManager;
	object.VATMode = data.VATMode;
	object.Import = data.Import;
	Form.ContractCurrency = data.Currency;
	
EndProcedure

&AtServer
Procedure SetCustomerDepositsContactManagerVATRate ( Object ) export
	
	fields = "OrganizationDeposit, Deposit, Contact, SalesManager, TaxGroup";
	data = DF.Values ( Object.Contract, fields );
	setObjectFields ( Object, "Customer", fields, data );
	
EndProcedure

&AtClient
Procedure SetWarehouseDeliveryAddress ( Object ) export
	
	fields = "Address";
	data = DF.Values ( Object.Warehouse, "Address" );
	setObjectFields ( Object, "WarehouseAddress", fields, data );
	
EndProcedure

&AtServer
Procedure SetVendorDeposits ( Object ) export
	
	setDeposits ( Object, "Vendor" );
	
EndProcedure

&AtServer
Procedure SetCustomerDeposits ( Object ) export
	
	setDeposits ( Object, "Customer" );
	
EndProcedure

&AtServer
Procedure setDeposits ( Object, DocumentClass )
	
	fields = "OrganizationDeposit, Deposit";
	data = DF.Values ( Object.Contract, fields );
	setObjectFields ( Object, DocumentClass, fields, data );
	
EndProcedure

Procedure setObjectFields ( Object, FieldsType, Fields, DataFields )
	
	fieldsArray = Conversion.StringToArray ( Fields );
	for each field in fieldsArray do
		fieldValue = DataFields [ field ];
		if ( not ValueIsFilled ( fieldValue ) ) then
			continue;
		endif; 
		if ( field = "OrganizationDeposit" ) then
			if ( FieldsType = "Customer" ) then
				Object.CustomerDeposit = fieldValue;
			else
				Object.VendorDeposit = fieldValue;
			endif; 
		elsif ( field = "SupplyManager" ) or ( field = "SalesManager" ) then
			Object.Manager = fieldValue;
		else
			Object [ field ] = fieldValue;
		endif; 
	enddo; 

EndProcedure
