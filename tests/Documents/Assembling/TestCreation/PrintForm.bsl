Click ( "#FormDocumentAssemblingAssembling" );
With ();
Put ( "#Language", "English" );
Click ( "#FormOK" );
With ( "Assembling: Print" );
Call ( "Common.CheckLogic", "#TabDoc" );
