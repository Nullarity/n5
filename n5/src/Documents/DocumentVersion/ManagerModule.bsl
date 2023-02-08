#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	Fields.Add ( "Subject" );
	StandardProcessing = false;
	
EndProcedure

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	Presentation = Metadata.Documents.DocumentVersion.Synonym + ": " + Left ( Data.Subject, 50 );
	
EndProcedure

Function Create ( Document, WeakRef = undefined ) export
	
	SetPrivilegedMode ( true );
	BeginTransaction ();
	reference = ? ( Document.IsNew (), Document.GetNewObjectRef (), Document.Ref );
	version = createVersion ( Document, reference, WeakRef );
	createAttachments ( reference, version.Ref );
	CKEditorSrv.CopyDocument ( Document.FolderID, version.FolderID );
	SetPrivilegedMode ( false );
	CommitTransaction ();
	return version.Ref;
	
EndFunction 

Function createVersion ( Document, Reference, WeakRef )
	
	version = CreateDocument ();
	FillPropertyValues ( version, Document );
	if ( WeakRef <> undefined ) then
		version.SetNewObjectRef ( WeakRef );
	endif; 
	version.SetNewNumber ();
	version.CurrentVersion = Reference;
	version.Content = new ValueStorage ( Document.Content.Get () );
	version.Data = new ValueStorage ( Document.Data.Get () );
	table = Document.Table;
	if ( table <> undefined ) then
		tabDoc = table.Get ();
		version.Table = new ValueStorage ( tabDoc, new Deflation ( 9 ) );
	endif; 
	version.FolderID  = new UUID ();
	version.Write ();
	return version;
	
EndFunction 

Procedure createAttachments ( Document, Version )
	
	recordset = InformationRegisters.Files.CreateRecordSet ();
	recordset.Filter.Document.Set ( Document );
	recordset.Read ();
	recordset2 = InformationRegisters.Files.CreateRecordSet ();
	recordset2.Filter.Document.Set ( Version );
	for each record in recordset do
		record2 = recordset2.Add ();
		FillPropertyValues ( record2, record );
		record2.Document = Version;
	enddo; 
	recordset2.Write ();
	
EndProcedure 

#endif