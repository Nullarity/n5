form = __.Form;

page = Activate ( "Records", form, "Group" );
With ( page );

table = Get ( "#Tasks" );
commands = table.GetCommandBar ();


table.DeleteRow (); // Remove artificial row

Click ( "Yes", With ( DialogsTitle ) );
With ( page );

Call ( "Table.AddEscape", table );

Click ( "Add", commands );

Set ( "Start", "10:00", table );
Set ( "Finish", "11:40", table );
Set ( "Description", "Some work", table );
Check ( "Duration", "1:40", table );

Click ( "Add", commands );
Set ( "Finish", "13:20", table );

Call ( "Table.CopyEscapeDelete", table );

CheckErrors ();