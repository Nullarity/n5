// Description:
// Activates table Row & Column

StandardProcessing = false;

table = _.Table;
search = new Map ();
search.Insert ( "#", _.Row );
table.GotoFirstRow ();
table.GotoRow ( search, RowGotoDirection.Down );
Activate ( _.Column, table );