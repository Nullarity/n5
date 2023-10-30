// Load issues from github

Call ( "Common.Init" );
CloseAll ();

OpenMenu ( "Sections panel / Time" );
OpenMenu ( "Functions menu / Issues" );
With ( "Issues" );
Click ( "#FormLoad" );
With ();
Set ( "#Repository", "n5" );
noissues = CurrentDate () + 86400;
Set ( "#Since", noissues );
Next ();
Click ( "#FormOK" );
