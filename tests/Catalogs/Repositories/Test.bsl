// Just create a repository

Call ( "Common.Init" );
CloseAll ();

id = TestingID ();

#region create
OpenMenu ( "Sections panel / Time" );
OpenMenu ( "Functions menu / Repositories" );
With ();
Click ( "#FormCreate" );
With ();
Set ( "#URL", id );
Set ( "#Description", id );
Next ();
Click ( "#SetToken" );
Set ( "#Token", "my token" );
Click ( "#FormWriteAndClose" );
#endregion