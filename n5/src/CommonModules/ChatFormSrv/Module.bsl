
Function ImageURL ( val ID ) export
	
	record = InformationRegisters.ChatPictures.CreateRecordKey ( new Structure ( "ID", ID ) );
	return GetUrl ( record, "Picture" );

EndFunction
