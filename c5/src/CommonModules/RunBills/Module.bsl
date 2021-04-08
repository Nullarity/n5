Procedure GetData ( Env ) export

	sqlFields ( Env );
	Env.Q.SetParameter ( "Ref", Env.Ref );
	SQL.Perform ( Env );
	setContext ( Env );
	sqlPayments ( Env );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlFields ( Env )
	
	s = "
	|// @Fields
	|select Documents.Date as Date, Documents.Contract as Contract, Documents.Base as Base, Documents.PointInTime as Timestamp
	|from Document." + Env.Document + " as Documents
	|where Documents.Ref = &Ref
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Procedure setContext ( Env )
	
	if ( Env.Type = Type ( "DocumentRef.Bill" ) ) then
		Env.Insert ( "IsOutgoingBill", true );
		Env.Insert ( "PaymentsRegister", "Payments" );
	else
		Env.Insert ( "IsOutgoingBill", false );
		Env.Insert ( "PaymentsRegister", "VendorDebts" );
	endif; 
	Env.Insert ( "PaymentsByBaseDocument", Env.Fields.Base <> undefined );
	
EndProcedure

Procedure sqlPayments ( Env )
	
	if ( Env.PaymentsByBaseDocument ) then
		s = "
		|// @PaymentFields
		|select Document.Option as Option, Document.PaymentDate as PaymentDate,
		|	Document.ChangePaymentDate as ChangePaymentDate, PaymentDetails.PaymentKey as PaymentKey
		|from Document." + Env.Document + " as Document
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.Option = Document.Option
		|	and PaymentDetails.Date = Document.PaymentDate
		|where Document.Ref = &Ref
		|;
		|select Payments.LineNumber as LineNumber, Payments.Option as Option, Payments.PaymentDate as PaymentDate,
		|	Payments.AmountPayment as AmountPayment, PaymentDetails.PaymentKey as PaymentKey, Payments.Document as Document
		|into Payments
		|from Document." + Env.Document + ".PaymentsByBase as Payments
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.Option = Payments.Option
		|	and PaymentDetails.Date = Payments.PaymentDate
		|where Payments.Ref = &Ref
		|index by Document
		|;
		|// #Payments
		|select Payments.LineNumber as LineNumber, Payments.Option as Option, Payments.PaymentDate as PaymentDate,
		|	Payments.AmountPayment as AmountPayment, Payments.PaymentKey as PaymentKey, Payments.Document as Document
		|from Payments as Payments
		|";
	else
		s = "
		|// #Payments
		|select Payments.Option as Option, Payments.PaymentDate as PaymentDate, Payments.Amount as AmountPayment,
		|	PaymentDetails.PaymentKey as PaymentKey
		|from Document." + Env.Document + ".Payments as Payments
		|	left join InformationRegister.PaymentDetails as PaymentDetails
		|	on PaymentDetails.Option = Payments.Option
		|	and PaymentDetails.Date = Payments.PaymentDate
		|where Payments.Ref = &Ref
		|";
	endif; 
	Env.Selection.Add ( s );
	
EndProcedure

Procedure MakePayments ( Env ) export
	
	recordset = Env.Registers [ Env.PaymentsRegister ];
	for each row in Env.Payments do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.Contract = Env.Fields.Contract;
		if ( row.PaymentKey = null ) then
			Env.PaymentDetails.Option = row.Option;
			Env.PaymentDetails.Date = row.PaymentDate;
			movement.PaymentKey = PaymentDetails.GetKey ( Env );
		else
			movement.PaymentKey = row.PaymentKey;
		endif; 
		movement.Document = Env.Ref;
		movement.Payment = row.AmountPayment;
		movement.Bill = row.AmountPayment;
	enddo; 
	
EndProcedure

Function MakePaymentsByBaseDocument ( Env ) export
	
	lockPayments ( Env );
	getPaymentsBalances ( Env );
	if ( not makePaymentsBill ( Env ) ) then
		return false;
	endif;
	return true;
	
EndFunction

Procedure lockPayments ( Env )
	
	lockData = new DataLock ();
	lockItem = lockData.Add ( "AccumulationRegister." + Env.PaymentsRegister );
	lockItem.Mode = DataLockMode.Exclusive;
	lockItem.SetValue ( "Contract", Env.Fields.Contract );
	lockItem.DataSource = Env.Payments;
	lockItem.UseFromDataSource ( "PaymentKey", "PaymentKey" );
	lockItem.UseFromDataSource ( "Document", "Document" );
	lockData.Lock ();
	
EndProcedure

Procedure getPaymentsBalances ( Env )
	
	fields = Env.Fields;
	sqlPaymentsBalances ( Env );
	Env.Q.SetParameter ( "Contract", fields.Contract );
	Env.Q.SetParameter ( "Timestamp", ? ( Env.Realtime, fields.Timestamp, undefined ) );
	SQL.Perform ( Env );
	
EndProcedure

Procedure sqlPaymentsBalances ( Env )
	
	s = "
	|// #PaymentsBalance
	|select PaymentsBalance.Document as Document, PaymentsBalance.Detail as Detail, PaymentDetails.Date as Date,
	|	PaymentDetails.PaymentKey as PaymentKey, PaymentDetails.Option as Option,
	|	PaymentsBalance.PaymentBalance - PaymentsBalance.BillBalance as AmountPayment
	|from AccumulationRegister." + Env.PaymentsRegister + ".Balance ( &Timestamp, Contract = &Contract
	|	and Document in ( select distinct Document from Payments ) ) as PaymentsBalance
	|	left join InformationRegister.PaymentDetails as PaymentDetails
	|	on PaymentDetails.PaymentKey = PaymentsBalance.PaymentKey
	|where PaymentsBalance.PaymentBalance > 0
	|or PaymentsBalance.BillBalance > 0
	|order by PaymentDetails.Date desc, Detail.Date desc
	|";
	Env.Selection.Add ( s );
	
EndProcedure

Function makePaymentsBill ( Env )
	
	p = new Structure ();
	setDecreaseParams ( Env, p );
	resultTable = CollectionsSrv.Decrease ( Env.PaymentsBalance, p.PaymentsTable, p );
	if ( p.PaymentsTable.Count () > 0 ) then
		showShortageBills ( Env, p.PaymentsTable );
		return false;
	endif; 
	makePaymentsMovements ( Env, resultTable );
	return true;
	
EndFunction

Procedure setDecreaseParams ( Env, Params )
	
	Params.Insert ( "FilterColumns", "Document, Option, PaymentDate" );
	Params.Insert ( "KeyColumn", "AmountPayment" );
	Params.Insert ( "KeyColumnAvailable", "AmountPaymentAvailable" );
	Params.Insert ( "DecreasingColumns2", "AmountPayment" );
	Params.Insert ( "PaymentsTable", Env.Payments.Copy () );
	
EndProcedure

Procedure showShortageBills ( Env, Table )
	
	p = new Structure ( "Amount, Document, AmountBalance" );
	for each row in Table do
		p.Amount = Conversion.NumberToMoney ( row.AmountPayment );
		p.AmountBalance = Conversion.NumberToMoney ( row.AmountPaymentAvailable );
		p.Document = row.Document;
		Output.PaymentsBillBalanceError ( p, Output.Row ( "PaymentsByBase", row.LineNumber, "AmountPayment" ), Env.Ref );
	enddo; 
	
EndProcedure

Procedure makePaymentsMovements ( Env, Table )
	
	recordset = Env.Registers [ Env.PaymentsRegister ];
	documentPaymentKey = getDocumentPaymentKey ( Env );
	for each row in Table do
		movement = recordset.AddReceipt ();
		movement.Period = Env.Fields.Date;
		movement.Contract = Env.Fields.Contract;
		movement.Document = row.Document;
		movement.Detail = row.Detail;
		movement.Bill = row.AmountPayment;
		if ( Env.PaymentFields.ChangePaymentDate ) then
			movement.PaymentKey = documentPaymentKey;
			movement.Payment = row.AmountPayment;
			reversePayment ( Env, row );
		else
			movement.PaymentKey = row.PaymentKey;
		endif; 
	enddo; 
	
EndProcedure

Procedure reversePayment ( Env, Row )
	
	recordset = Env.Registers [ Env.PaymentsRegister ];
	movement = recordset.AddReceipt ();
	movement.Period = Env.Fields.Date;
	movement.Contract = Env.Fields.Contract;
	movement.Document = Row.Document;
	movement.Detail = Row.Detail;
	movement.PaymentKey = Row.PaymentKey;
	movement.Payment = - Row.AmountPayment;
	
EndProcedure

Function getDocumentPaymentKey ( Env )
	
	paymentKey = Env.PaymentFields.PaymentKey;
	if ( paymentKey = null ) then
		Env.PaymentDetails.Option = Env.PaymentFields.Option;
		Env.PaymentDetails.Date = Env.PaymentFields.PaymentDate;
		paymentKey = PaymentDetails.GetKey ( Env );
	endif; 
	return paymentKey;
	
EndFunction

Procedure SetRegistersWriteFlag ( Env ) export
	
	Env.Registers [ Env.PaymentsRegister ].Write = true;
	
EndProcedure
