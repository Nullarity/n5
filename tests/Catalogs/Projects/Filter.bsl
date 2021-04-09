StandardProcessing = false;

Call ( "Common.Init" );

CloseAll ();
MainWindow.ExecuteCommand ( "e1cib/list/Catalog.Projects" );

form = With ( "Projects" );
list = Activate ( "#List" );
description = _.Description;

p = Call ( "Common.Find.Params" );
p.Where = "Description";
p.What = description;
p.Button = "#ListContextMenuFind";
Call ( "Common.Find", p );

With ( form );

return list;