#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure FillCheckProcessing ( Cancel, CheckedAttributes )
	
	if ( Status = 1 ) then
		if ( not checkTables () ) then
			Cancel = true;
		endif;
	else
		Output.LoadPaymentsFirst ( , "Path" );
		Cancel = true;
	endif;
	
EndProcedure

Function checkTables ()
	
	error = false;
	paymentsExist = false;
	tables = new Array ();
	tables.Add ( Receipts );
	tables.Add ( Expenses );
	for each table in tables do
		for each row in table do
			if ( not row.Download ) then
				continue;
			endif;
			problems = new Array ();
			if ( row.Amount = 0) then
				problems.Add ( "Amount" );
			endif;
			if ( row.BankOperation.IsEmpty () ) then
				problems.Add ( "BankOperation" );
			elsif ( row.Operation.IsEmpty ()
				and ( row.BankOperation = Enums.BankOperations.OtherExpense
					or row.BankOperation = Enums.BankOperations.OtherReceipt ) ) then
				problems.Add ( "Operation" );
			endif;
			if ( row.Account.IsEmpty () ) then
				problems.Add ( "Account" );
			endif;
			operation = row.BankOperation;
			if ( operation = Enums.BankOperations.Payment
				or operation = Enums.BankOperations.ReturnFromVendor
				or operation = Enums.BankOperations.VendorPayment
				or operation = Enums.BankOperations.ReturnToCustomer ) then
				if ( not ValueIsFilled ( row.Dim1 ) ) then
					problems.Add ( "Dim1" );
				endif;
				if ( not ValueIsFilled ( row.Dim2 ) ) then
					problems.Add ( "Dim2" );
				endif;
				if ( row.AdvanceAccount.IsEmpty () ) then
					problems.Add ( "AdvanceAccount" );
				endif;
			endif;
			if ( problems.Count () > 0 ) then
				error = true;
				tableName = ? ( table = Receipts, "Receipts", "Expenses" );
				line = row.LineNumber;
				for each problem in problems do
					Output.FieldIsEmpty ( , Output.Row ( tableName, line, problem ), Ref );
				enddo;
			endif;
			paymentsExist = true;
		enddo;
	enddo;
	if ( not paymentsExist ) then
		Output.PaymentsNotSelected ( , "Details" );
		error = true;
	endif;
	return not error;
	
EndFunction

Procedure BeforeWrite ( Cancel, WriteMode, PostingMode )

	if ( DataExchange.Load ) then
		return;
	endif;
	if ( IsNew () ) then
		return;
	endif;
	if ( DeletionMark ) then
		setDeletion ( true );
	elsif ( DF.Pick ( Ref, "DeletionMark" ) ) then
		setDeletion ( false );
	endif;

EndProcedure

Procedure setDeletion ( Mark )
	
	for each document in findMarked ( not Mark ) do
		document.GetObject ().SetDeletionMark ( mark );
	enddo;
	
EndProcedure

Function findMarked ( Mark )
	
	s = "
	|select Receipts.Document as Document
	|from Document.LoadPayments.Receipts as Receipts
	|where Receipts.Ref = &Ref
	|and Receipts.Document.DeletionMark = &Mark
	|union all
	|select Expenses.Document
	|from Document.LoadPayments.Expenses as Expenses
	|where Expenses.Ref = &Ref
	|and Expenses.Document.DeletionMark = &Mark";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	q.SetParameter ( "Mark", Mark );
	return q.Execute ().Unload ().UnloadColumn ( "Document" );
	
EndFunction

Procedure UndoPosting ( Cancel )
	
	unpost ();
	
EndProcedure

Procedure unpost ()
	
	for each document in findPosted () do
		document.GetObject ().Write ( DocumentWriteMode.UndoPosting );
	enddo;
	
EndProcedure

Function findPosted ()
	
	s = "
	|select Receipts.Document as Document
	|from Document.LoadPayments.Receipts as Receipts
	|where Receipts.Ref = &Ref
	|and Receipts.Document.Posted
	|union all
	|select Expenses.Document
	|from Document.LoadPayments.Expenses as Expenses
	|where Expenses.Ref = &Ref
	|and Expenses.Document.Posted";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	return q.Execute ().Unload ().UnloadColumn ( "Document" );
	
EndFunction

#endif
