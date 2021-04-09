form = With ( "Bank accounts" );
list = Activate ( "#List" );
search = new Map ();
search.Insert ( "Description", _ );
try
	isNew = not list.GotoRow ( search, RowGotoDirection.Down );
except
	Call ( "Catalogs.BankAccounts.Create", _ );
	isNew = true;
endtry;
if ( isNew ) then
	With ( "Bank accounts" );
	Click ( "#FormRefresh" );
	list = Activate ( "#List" );
	list.GotoFirstRow ();
	list.GotoRow ( search, RowGotoDirection.Down );
endif;
Click ( "#FormChoose" );