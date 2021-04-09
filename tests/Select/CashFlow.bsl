form = With ( "Cash Flows" );
list = Activate ( "#List" );
search = new Map ();
search.Insert ( "Description", _ );
try
	isNew = not list.GotoRow ( search, RowGotoDirection.Down );
except
	Call ( "Catalogs.CashFlow.Create", _ );
	isNew = true;
endtry;
if ( isNew ) then
	With ( form );
	Click ( "#FormRefresh" );
	list = Activate ( "#List" );
	list.GotoFirstRow ();
	list.GotoRow ( search, RowGotoDirection.Down );
endif;
Click ( "#FormChoose" );