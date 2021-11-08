Function Search ( val Ref, val OldOperation = undefined ) export
	
	if ( PettyCash.Voucher ( Ref, OldOperation ) ) then
		return Documents.CashVoucher.FindByAttribute ( "Base", Ref );
	else
		return Documents.CashReceipt.FindByAttribute ( "Base", Ref );
	endif; 
	
EndFunction 

Function Voucher ( val Reference, val OldOperation ) export
	
	type = TypeOf ( Reference );
	if ( type = Type ( "DocumentRef.Entry" ) ) then
		if ( ValueIsFilled ( OldOperation ) ) then
			return DF.Pick ( OldOperation, "Operation" ) = Enums.Operations.CashExpense;
		else
			return DF.Pick ( Reference, "Operation.Operation" ) = Enums.Operations.CashExpense;
		endif;
	else
		return Metadata.DefinedTypes.CashVoucherBase.Type.ContainsType ( type );
	endif; 

EndFunction 
