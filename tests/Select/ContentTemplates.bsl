form = With ( "Templates of Contents" );
list = Activate ( "#List" );
search = new Map ();
search.Insert ( "Description", _ );
try
	isNew = not list.GotoRow ( search, RowGotoDirection.Down );
except
	Call ( " );
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