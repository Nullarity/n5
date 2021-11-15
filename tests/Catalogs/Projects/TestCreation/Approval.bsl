form = __.Form;
//page = Activate ( "Approval", form );
//With ( page );

checkbox = "#UseApprovingProcess";
Click ( checkbox );
//Click ( "Yes", With ( DialogsTitle ) );
//With ( page );
CheckState ( "#ApprovalList", "Enable" );
Click ( checkbox );
CheckState ( "#ApprovalList", "Enable", false );