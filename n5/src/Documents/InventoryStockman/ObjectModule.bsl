
Procedure OnWrite ( Cancel )
	
	if ( DataExchange.Load ) then
		return;
	endif;
	Documents.InventoryStockman.Post ( Ref );
	
EndProcedure
