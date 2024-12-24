Procedure CreateContract ( Object, Ref ) export
	
	SetPrivilegedMode ( true );
	customer = Object.Customer;
	vendor = Object.Vendor;
	settings = Logins.Settings ( "Company" );
	obj = Catalogs.Contracts.CreateItem ();
	Metafields.Constructor ( obj );
	obj.DataExchange.Load = true;
	obj.Owner = ref;
	obj.Creator = SessionParameters.User;
	obj.Description = Output.General ();
	obj.Company = settings.Company;
	obj.Currency = Application.Currency ();
	obj.Customer = customer;
	obj.Vendor = vendor;
	data = Catalogs.Contracts.GetDefaults ( Ref, customer );
	monthlyAdvances = data.AdvancesMonthly;
	closeAdvances = not monthlyAdvances;
	if ( customer ) then
		obj.CustomerTerms = Constants.Terms.Get ();
		obj.CustomerPayment = Constants.PaymentMethod.Get ();
		obj.CustomerVATAdvance = data.VATAdvance;
		obj.CustomerAdvancesMonthly = monthlyAdvances;
		obj.CustomerAdvances = closeAdvances;
	endif;
	if ( vendor ) then
		obj.VendorTerms = Constants.VendorTerms.Get ();
		obj.VendorPayment = Constants.VendorPaymentMethod.Get ();
		obj.VendorAdvancesMonthly = monthlyAdvances;
		obj.VendorAdvances = closeAdvances;
	endif; 
	obj.Write ();
	if ( customer ) then
		Object.CustomerContract = obj.Ref;
	endif; 
	if ( vendor ) then
		Object.VendorContract = obj.Ref;
	endif; 
	
EndProcedure 
