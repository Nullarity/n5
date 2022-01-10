
Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	Documents.ReceiptStockman.Post ( Ref );
	
EndProcedure
