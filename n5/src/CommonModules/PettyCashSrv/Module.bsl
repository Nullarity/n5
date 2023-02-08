Function Search ( val Ref ) export
	
	if ( PettyCash.Voucher ( Ref ) ) then
		return Documents.CashVoucher.FindByAttribute ( "Base", Ref );
	else
		return Documents.CashReceipt.FindByAttribute ( "Base", Ref );
	endif; 
	
EndFunction 

Function Voucher ( val Reference ) export
	
	type = TypeOf ( Reference );
	if ( type = Type ( "DocumentRef.Entry" ) ) then
		return DF.Pick ( Reference, "Method" ) = Enums.Operations.CashExpense;
	else
		return Metadata.DefinedTypes.CashVoucherBase.Type.ContainsType ( type );
	endif; 

EndFunction 
