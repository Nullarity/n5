Call ( "Common.Init" );
CloseAll ();

Commando ( "e1cib/list/Catalog.Companies" );
form = With ( "Companies" );
list = Activate ( "#List" );
search = new Map ();
search.Insert ( "Description", __.Company );
list.GotoRow ( search, RowGotoDirection.Down );
Click ( "#ListContextMenuChange", list.GetCommandBar () );
form = With ( "*(Companies)" );
Choose ( "#BankAccount" );
Call ( "Select.BankAccount", Call ( "Select.MainCurrencyName" ) );
With ( form );
Click ( "#FormWriteAndClose", form.GetCommandBar () );