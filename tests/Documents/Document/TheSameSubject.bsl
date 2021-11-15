Call ( "Common.Init" );
CloseAll ();

subjectOriginal = "_Document: " + CurrentDate ();
subject2ShouldBe = subjectOriginal + " #1";

Call ( "Documents.Document.CreateAndPublish", subjectOriginal );
subject2 = Call ( "Documents.Document.CreateAndPublish", subjectOriginal );

if ( subject2 <> subject2ShouldBe ) then
	raise "Document should have subject: " + subject2ShouldBe + " but actual subject is " + subject2;
endif;
