Procedure Pay ( payment_status, txn_id, receiver_email, mc_gross, mc_currency, custom, payer_email ) export
	
	payPallEmail = Constants.PayPalEmail.Get ();
	try
		WriteLogEvent ( "PayPal.Pay", , , , payment_status + ", " + txn_id + ", " + receiver_email + ", " + mc_gross + ", " + mc_currency + ", " + custom + ", " + payer_email );
		if ( payment_status <> "Completed" ) then
			raise "PayPal: " + payment_status + "<> Completed";
		endif; 
		if ( mc_currency <> "USD" ) then
			raise "PayPal: " + mc_currency + "<> USD";
		endif; 
		if ( receiver_email <> payPallEmail ) then
			raise "PayPal: " + "receiver_email " + receiver_email + " <> " + payPallEmail;
		endif; 
		tenantOrder = getTenantOrder ( custom, mc_gross );
		if ( tenantOrder = undefined ) then
			raise "PayPal: Tenant order " + custom + " not found";
		endif; 
		writePayment ( tenantOrder, txn_id, payer_email );
		WriteLogEvent ( "PayPal.Pay", , , , "Tenant order " + custom + " payed" );
	except
		WriteLogEvent ( "PayPal.Pay", , , , ErrorDescription () );
	endtry;
	
EndProcedure

Function getTenantOrder ( DocumentNumber, Amount )
	
	s = "
	|select TenantOrders.Ref as Ref
	|from Document.TenantOrder as TenantOrders
	|	//
	|	// TenantPayments
	|	//
	|	left join Document.TenantPayment as TenantPayments
	|	on TenantPayments.TenantOrder = TenantOrders.Ref
	|	and TenantPayments.Posted
	|where not TenantOrders.DeletionMark
	|and TenantOrders.Number = &DocumentNumber
	|and TenantOrders.Amount = &Amount
	|and TenantPayments.TenantOrder is null
	|";
	q = new Query ( s );
	q.SetParameter ( "DocumentNumber", DocumentNumber );
	q.SetParameter ( "Amount", Number ( Amount ) );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Ref );
	
EndFunction 

Procedure writePayment ( TenantOrder, txn_id, payer_email )
	
	makeIPN ( TenantOrder, txn_id, payer_email );
	createTenantPayment ( TenantOrder );
	
EndProcedure 

Procedure makeIPN ( TenantOrder, txn_id, payer_email )
	
	record = InformationRegisters.IPN.CreateRecordManager ();
	record.TenantOrder = TenantOrder;
	record.Date = CurrentSessionDate ();
	record.txn_id = txn_id;
	record.payer_email = payer_email;
	record.Write ();
	
EndProcedure 

Procedure createTenantPayment ( TenantOrder )
	
	fields = DF.Values ( TenantOrder, "Amount, Bonus" );
	obj = Documents.TenantPayment.CreateDocument ();
	obj.Creator = SessionParameters.User;
	obj.Amount = fields.Amount;
	obj.PaymentDate = CurrentSessionDate ();
	obj.TenantOrder = TenantOrder;
	obj.Amount = fields.Amount;
	obj.Bonus = fields.Bonus;
	obj.Write ( DocumentWriteMode.Posting );
	
EndProcedure 
