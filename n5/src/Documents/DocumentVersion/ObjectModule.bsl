#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure BeforeDelete ( Cancel )
	
	CKEditorSrv.Clean ( FolderID );
	
EndProcedure

#endif