// Create time entry and change time back and forth with testing

Call ( "Common.Init" );
CloseAll ();

Commando("e1cib/command/Document.TimeEntry.Create");
Tasks = Get ( "#Tasks" );
Click ( "#TasksAdd" );
Set ( "#TasksTimeStart", "11:00", Tasks );
Tasks.EndEditRow ( false );
Set ( "#TasksTimeEnd", "12:00", Tasks );

Set ( "#TasksTimeStart", "12:00", Tasks );
Check ( "#TasksTimeEnd", "", Tasks );

Set ( "#TasksTimeEnd", "10:00", Tasks );
Check ( "#TasksTimeStart", "", Tasks );

Disconnect();

Connect ();

Set ( "#TasksTimeEnd", "13:00", Tasks );
