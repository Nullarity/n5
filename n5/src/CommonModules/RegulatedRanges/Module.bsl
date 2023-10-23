
Procedure Enroll ( Object ) export
	
	SetPrivilegedMode ( true );
	rangeData = DF.Values ( Object.Range, "Real, Online, Finish" );
	makeWritingOff ( Object, rangeData );
	makeStatuses ( Object, rangeData );
	if ( ValueIsFilled ( Object.Base ) ) then
		registerForm ( Object );
	endif;
	
EndProcedure

Procedure makeWritingOff ( Object, RangeData )
	
	writing = findWritingOff ( Object );
	if ( Object.Range.IsEmpty ()
		or RangeData.Online
		or not RangeData.Real ) then
		if ( writing <> undefined ) then
			obj = writing.Ref.GetObject ();
			obj.SetDeletionMark ( true );
		endif;
		return;
	endif;
	if ( Object.Status = Enums.FormStatuses.Saved ) then
		if ( writing = undefined ) then
			return;
		elsif ( writing.Posted ) then
			mode = DocumentWriteMode.UndoPosting;
		else
			mode = DocumentWriteMode.Write;
		endif;
	else
		mode = DocumentWriteMode.Posting;
	endif;
	obj = ? ( writing = undefined, Documents.WriteOffForm.CreateDocument (), writing.Ref.GetObject () );
	obj.Fill ( Object );
	obj.Write ( mode );

EndProcedure

Function findWritingOff ( Object )
	
	s = "
	|select top 1 Documents.Ref as Ref, Documents.Posted as Posted
	|from Document.WriteOffForm as Documents
	|where not Documents.DeletionMark
	|and Documents.Base = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Object.Ref );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ] );
	
EndFunction

Procedure makeStatuses ( Object, RangeData )
	
	r = InformationRegisters.RangeStatuses.CreateRecordSet ();
	r.Filter.Recorder.Set ( Object.Ref );
	range = Object.Range;
	if ( not range.IsEmpty () ) then
		if ( not RangeData.Online
			and ( Object.FormNumber = RangeData.Finish ) ) then
			movement = r.Add ();
			movement.Period = Object.Date;
			movement.Range = range;
			movement.Status = Enums.RangeStatuses.Finished;
		endif;
	endif;
	r.Write ();
	
EndProcedure

Procedure registerForm ( Object )
	
	document = Object.Base;
	lockForm ( document );
	change = registrationNeeded ( Object );
	if ( change = undefined ) then
		r = InformationRegisters.Forms.CreateRecordManager ();
		r.Document = document;
		r.Delete ();
	elsif ( change ) then
		r = InformationRegisters.Forms.CreateRecordManager ();
		r.Document = document;
		r.Status = Object.Status;
		r.Form = Object.Ref;
		r.Number = Object.Number;
		r.Write ();
	endif;
	
EndProcedure

Procedure lockForm ( Document )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Forms" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Document", Document );
	lock.Lock ();
	
EndProcedure

Function registrationNeeded ( Object )
	
	formName = Metadata.FindByType ( TypeOf ( Object.Ref ) ).Name;
	s = "
	|select case when Current.Document is null then true else false end as Change
	|from (
	|	select top 1 Last.Ref
	|	from Document." + formName + " as Last
	|	where Last.Base = &Base
	|	and not Last.DeletionMark
	|	order by Last.Date desc
	|) as Last
	|	//
	|	// Current
	|	//
	|	left join InformationRegister.Forms as Current
	|	on Current.Form = Last.Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Base", Object.Base );
	table = q.Execute ().Unload ();
	return ? ( table.Count () = 0, undefined, table [ 0 ].Change );
	
EndFunction

Procedure Fill ( Object ) export

	range = Object.Range;
	emptyRange = range.IsEmpty ();
	if ( emptyRange ) then
		data = CoreLibrary.SeriesAndNumber ( Object.Number );
		Object.Series = data.Series;
		documentNumber = data.Number;
		Object.FormNumber = documentNumber;
		Object.Number = RegulatedRanges.BuildNumber ( , Object.Series, documentNumber );
	else
		if ( DF.Pick ( Object.Range, "Online" ) ) then
			changedManually = ( Object.Number = "" ) and not emptyNumber ( Object );  
			if ( changedManually ) then
				Object.Number = RegulatedRanges.BuildNumber ( range, Object.Series, Object.FormNumber );
			endif;
		else
			if ( emptyNumber ( Object ) ) then
				data = getNext ( range );
				Object.Series = data.Series;
				Object.FormNumber = data.Number;
			else
				pushNumber ( range, Object.Series, Object.FormNumber );
			endif;
			Object.Number = RegulatedRanges.BuildNumber ( range, Object.Series, Object.FormNumber );
		endif;
	endif;

EndProcedure

Function emptyNumber ( Object )
	
	return IsBlankString ( Object.Series ) and Object.FormNumber = 0;
	
EndFunction

Function getNext ( Range )
	
	lock ( Range );
	data = getData ( Range );
	return newNumber ( range, data );
	
EndFunction

Procedure lock ( Range )
	
	lock = new DataLock ();
	item = lock.Add ( "InformationRegister.Ranges" );
	item.Mode = DataLockMode.Exclusive;
	item.SetValue ( "Range", Range );
	lock.Lock ();
	
EndProcedure

Function getData ( Range )
	
	s = "
	|select Ranges.Prefix as Prefix, Ranges.Start as Start, Ranges.Finish as Finish,
	|	isnull ( LastRanges.Last + 1, Ranges.Start ) as Next, Statuses.Status as Status
	|from Catalog.Ranges as Ranges
	|	//
	|	// LastRanges
	|	//
	|	left join InformationRegister.Ranges as LastRanges
	|	on LastRanges.Range = Ranges.Ref
	|	//
	|	// Statuses
	|	//
	|	left join InformationRegister.RangeStatuses as Statuses
	|	on Statuses.Range = Ranges.Ref
	|where Ranges.Ref = &Range
	|";
	q = new Query ( s );
	q.SetParameter ( "Range", Range );
	return q.Execute ().Unload () [ 0 ];
	
EndFunction

Function newNumber ( Range, Data )
	
	next = data.Next;
	if ( next > data.Finish ) then
		raise Output.RangeFinished ( new Structure ( "Range", Range ) );
	elsif ( data.Status = null ) then
		raise Output.RangeInactive ( new Structure ( "Range", Range ) );
	endif;
	commit ( Range, next );
	return new Structure ( "Series, Number", Data.Prefix, next );
	
EndFunction

Procedure commit ( Range, Number )
	
	SetPrivilegedMode ( true );
	r = InformationRegisters.Ranges.CreateRecordManager ();
	r.Range = Range;
	r.Last = Number;
	r.Write ();
	
EndProcedure

Function BuildNumber ( Range = undefined, Series, Number, Next = false ) export
	
	prefix = TrimR ( Series );
	if ( Range = undefined ) then
		if ( Next ) then
			n = 1 + Conversion.StringToNumber ( Number );
			n = formatNumber ( n, StrLen ( Number ) );
		else
			n = Number;
		endif;
		return prefix + n;
	else
		n = ? ( Next, Number + 1, Number );
		return prefix + formatNumber ( n, DF.Pick ( Range, "Length" ) );
	endif;
	
EndFunction

Function formatNumber ( Number, Lengh )

	return Format ( Number, "NG=;NLZ=;ND=" + Lengh );

EndFunction

Procedure pushNumber ( Range, Series, Number )
	
	lock ( Range );
	data = getData ( Range );
	shiftRange ( Range, Series, Number, data );
	
EndProcedure

Procedure shiftRange ( Range, Series, Number, Data )
	
	if ( data.Status = null ) then
		raise Output.RangeInactive ( new Structure ( "Range", Range ) );
	endif;
	ok = TrimAll ( Series ) = data.Prefix
	and Number >= data.Start
	and Number <= data.Finish;
	if ( not ok ) then
		raise Output.RangeError ( new Structure ( "Range, Series, Number", Range, Series, Number ) );
	endif;
	shift = ( Number - data.Next );
	if ( shift = 0 ) then
		commit ( Range, Number );
	elsif ( shift > 0 ) then
		raise Output.RangeJumpstart ( new Structure ( "Range, Number", Range, Number ) );
	endif;
	
EndProcedure

Function Duplication ( Object ) export
	
	SetPrivilegedMode ( true );
	if ( numberComing ( Object )
		or formNotFound ( Object ) ) then
		return false;
	else
		Output.FormExists ( , "FormNumber", Object.Ref );
		return true;
	endif;
	
EndFunction

Function numberComing ( Object )
	
	return DF.Pick ( Object.Range, "Online" )
	and Object.Series = ""
	and Object.FormNumber = 0;
	
EndFunction

Function formNotFound ( Object )
	
	meta = Metadata.FindByType ( TypeOf ( Object.Ref ) );
	s = "
	|select top 1 1
	|from Document." + meta.Name + " as Documents
	|where Documents.Number = &Number
	|and Documents.Ref <> &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Number", Object.Number );
	q.SetParameter ( "Ref", Object.Ref );
	return q.Execute ().IsEmpty ();
	
EndFunction