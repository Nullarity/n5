Function Values ( val Ref, val Fields ) export
	
	set = ? ( TypeOf ( Fields ) = Type ( "Array" ), StrConcat ( Fields, "," ), Fields );
	meta = Ref.Metadata ();
	typesStructure = getTypes ( meta, set );
	s = "
	|select allowed " + set + "
	|from " + meta.FullName () + " as T_a_b_l_e
	|where T_a_b_l_e.Ref = &Ref
	|";
	q = new Query ( s );
	q.SetParameter ( "Ref", Ref );
	queryResult = q.Execute ();
	selection = queryResult.Select ();
	selection.Next ();
	result = new Structure ();
	for each column in queryResult.Columns do
		name = column.Name;
		if ( Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.Russian ) then
			if ( name = "Код" ) then
				name = "Code";
			elsif ( name = "Наименование" ) then
				name = "Description";
			endif; 
		endif; 
		valueType = typesStructure [ name ];
		value = selection [ name ];
		if ( valueType <> undefined ) then
			value = valueType.AdjustValue ( value );
		endif; 
		result.Insert ( name, value );
	enddo; 
	return result;
	
EndFunction

Function getTypes ( Meta, Fields )
	
	var field;
	var name;
	types = new Structure ();
	attributesArray = Conversion.StringToArray ( Fields );
	for each attribute in attributesArray do
		setFieldAndName ( attribute, field, name );
		types.Insert ( name, getFieldType ( meta, field ) );
	enddo; 
	return types;
	
EndFunction

Procedure setFieldAndName ( Attribute, Field, Name )
	
	synonym = Find ( Attribute, " as " );
	if ( synonym = 0 ) then
		Name = StrReplace ( Attribute, ".", "" );
		Field = Attribute;
	else
		Field = Left ( Attribute, synonym - 1 );
		Name = Mid ( Attribute, synonym + 4 );
	endif; 
	
EndProcedure

Function getFieldType ( Meta, Field )
	
	currentMeta = Meta;
	attributesArray = Conversion.StringToArray ( Field, "." );
	for each attribute in attributesArray do
		foundAttr = currentMeta.Attributes.Find ( attribute );
		if ( foundAttr = undefined ) then
			if ( Metadata.Tasks.Contains ( currentMeta ) ) then
				foundAttr = currentMeta.AddressingAttributes.Find ( attribute );
			elsif ( Metadata.ChartsOfAccounts.Contains ( currentMeta ) ) then
				foundAttr = currentMeta.AccountingFlags.Find ( attribute );
			endif;
			if ( foundAttr = undefined ) then
				foundAttr = currentMeta.StandardAttributes [ attribute ]; // StandardAttributes does not support Find () method
			endif; 
		endif; 
		currentType = foundAttr.Type;
		currentTypeTypes = currentType.Types ();
		if ( currentType = Type ( "Date" )
			or currentType = Type ( "String" )
			or currentType = Type ( "Number" )
			or currentType = Type ( "Boolean" )
			or currentType = Type ( "ValueStorage" ) ) then
			break;
		endif; 
		if ( currentTypeTypes.Count () > 1 ) then
			currentType = undefined;
			break;
		endif; 
		currentMeta = Metadata.FindByType ( currentTypeTypes [ 0 ] );
	enddo; 
	return currentType;

EndFunction

Function Pick ( val Ref, val Field, val Default = undefined ) export
	
	if ( Default <> undefined
		and Ref.IsEmpty () ) then
		return Default;
	endif; 
	name = fieldName ( Field );
	return Values ( Ref, Field ) [ name ];
	
EndFunction

Function fieldName ( Field )
	
	synonym = Find ( Field, " as " );
	if ( synonym = 0 ) then
		return StrReplace ( Field, ".", "" );
	else
		return Mid ( Field, synonym + 4 );
	endif; 
	
EndFunction

Function GetOriginal ( Exception, Field, Value, Owner = undefined ) export
	
	if ( not ValueIsFilled ( Value ) ) then
		return undefined;
	endif; 
	s = "
	|select allowed top 1 Ref as Ref
	|from " + Metadata.FindByType ( TypeOf ( Exception ) ).FullName () + "
	|where " + Field + " = &" + Field;
	if ( Owner <> undefined ) then
		s = s + " and Owner = &Owner";
	endif; 
	if ( not Exception.IsEmpty () ) then
		s = s + " and Ref <> &Ref";
	endif; 
	q = new Query ( s );
	q.SetParameter ( "Ref", Exception );
	q.SetParameter ( "Owner", Owner );
	q.SetParameter ( Field,	Value );
	result = q.Execute ().Unload ();
	return ? ( result.Count () = 0, undefined, result [ 0 ].Ref );
		
EndFunction

Procedure MakeUnique ( Object, Field, LockFields ) export
	
	meta = Object.Metadata ();
	q = lookingQuery ( meta, Object, Field );
	lockObjects ( meta, LockFields );
	description = Object [ Field ];
	for i = 0 to 999 do
		variant = description + ? ( i = 0, "", " #" + Format ( i, "NG=" ) );
		q.SetParameter ( "Description", variant );
		if ( q.Execute ().IsEmpty () ) then
			break;
		endif; 
	enddo; 
	if ( i > 0 ) then
		Object [ Field ] = variant;
	endif; 

EndProcedure 

Function lookingQuery ( Meta, Object, Field )
	
	q = new Query ();
	s = "
	|select top 1 1
	|from " + Meta.FullName () + " as List
	|where List." + Field + " = &Description
	|and List.Ref <> &Ref
	|";
	if ( Metadata.Catalogs.Contains ( Meta )
		and Meta.Owners.Count () > 0 ) then
		s = s + "
		|and List.Owner = &Owner
		|";
		q.SetParameter ( "Owner", Object.Owner );
	endif; 
	q.Text = s;
	q.SetParameter ( "Ref", Object.Ref );
	return q;
	
EndFunction

Procedure lockObjects ( Meta, LockFields )
	
	lock = new DataLock ();
	item = lock.Add ( Meta.FullName () );
	item.Mode = DataLockMode.Exclusive;
	if ( LockFields <> undefined ) then
		for each field in LockFields do
			item.SetValue ( field.Key, field.Value );
		enddo;
	endif;
	lock.Lock ();
	
EndProcedure 

Procedure SetNewCode ( Object, Initial = undefined ) export
	
	SetPrivilegedMode ( true );
	if ( Initial = undefined ) then
		Object.SetNewCode ();
	else
		Object.Code = Initial;
	endif;
	if ( codeExists ( Object ) ) then
		newTransaction = not TransactionActive ();
		if ( newTransaction ) then
			BeginTransaction ();
		endif;
		freeze ( Object );
		if ( TypeOf ( Object.Code ) = Type ( "Number" ) ) then
			setNumberCode ( Object );
		else
			setStringCode ( Object );
		endif;
		if ( newTransaction ) then
			CommitTransaction ();
		endif;
	endif;
	SetPrivilegedMode ( false );
	
EndProcedure

Function codeExists ( Object )
	
	code = Object.Code;
	meta = Object.Metadata ();
	name = meta.Name;
	if ( Metadata.Catalogs.Contains ( meta ) ) then
		item = Catalogs [ name ].FindByCode ( code );
	else
		item = ChartsOfCharacteristicTypes [ name ].FindByCode ( code );
	endif;
	return ValueIsFilled ( item );
	
EndFunction

Procedure freeze ( Object )
	
	lockData = new DataLock ();
	lockItem = lockData.Add ( Object.Metadata ().FullName () );
	lockItem.Mode = DataLockMode.Exclusive;
	lockData.Lock ();
	
EndProcedure

Procedure setNumberCode ( Object )
	
	q = new Query ( "select max ( Code ) as Code from " + Object.Metadata ().FullName () );
	selection =  q.Execute ().Select ();
	while ( selection.Next () ) do
		Object.Code = selection.Code + 1;
	enddo;
	
EndProcedure

Procedure setStringCode ( Object )
	
	code = Object.Code;
	maxLenght = Object.Metadata ().CodeLength;
	nodePrefix = CatalogEvents.GetPrefix ( Object );
	codeStructure = codeInfo ( code );
	prefix = codeStructure.Prefix;
	number = codeStructure.Number;
	prefixLenght = StrLen ( prefix );
	exists = addNumbers ( Object, prefix, number );
	while ( exists ) do
		i = 0;
		while ( exists and i < prefixLenght ) do
			char = CharCode ( prefix, prefixLenght - i );
			while ( exists and ( isEnglish ( char, false )
				or isRussian ( char, false ) ) ) do
				oldPrefix = Left ( prefix, prefixLenght - i );
				if ( oldPrefix = nodePrefix ) then
					break;
				endif;
				newPrefix = Left ( prefix, prefixLenght - i - 1 );
				prefix = newPrefix + Char ( char + 1 );
				exists = addNumbers ( Object, prefix );
				char = CharCode ( prefix, prefixLenght - i );
			enddo;
			if ( oldPrefix <> undefined and oldPrefix = nodePrefix ) then
				break;
			endif;
			i = i + 1;
		enddo;
		if ( exists and prefixLenght < maxLenght ) then
			newChar = Char ( 65 );
			i = 0;
			while ( i < prefixLenght ) do
				if ( isEnglish ( char, true, newChar )
					or isRussian ( char, true, newChar ) ) then
					break;
				endif;
				i = i + 1;
			enddo;
			prefix = prefix + newChar;
			prefixLenght = StrLen ( prefix );
			exists = addNumbers ( Object, prefix );
		else
			break;
		endif;
	enddo;
	
EndProcedure

Function codeInfo ( Code )
	
	lenght = StrLen ( Code );
	number = undefined;
	prefix = "";
	for i = 1 to lenght do
		s = Right ( Code, i );
		try
			number = Number ( s );
		except
			prefix = Left ( Code, lenght - i + 1 );
			break;
		endtry;
	enddo;
	return new Structure ( "Prefix, Number", prefix, number );
	
EndFunction

Function isEnglish ( Char, IncludingLast, FirstChar = undefined )
	
	if ( charInRange ( Char, 65, 90, true, IncludingLast ) ) then
		FirstChar = Char ( 65 );
		return true;
	elsif ( charInRange ( Char, 97, 122, true, IncludingLast ) ) then
		FirstChar = Char ( 97 );
		return true;
	else
		return false;
	endif;
	
EndFunction

Function charInRange ( CharCode, BottomBound, UpperBound, IncludeBottomBound = true, IncludeUpperBound = true )
	
	return ( ? ( IncludeBottomBound, CharCode >= BottomBound, CharCode > BottomBound ) 
	and	? ( IncludeUpperBound, CharCode <= UpperBound, CharCode < UpperBound ) );
	
EndFunction

Function isRussian ( Char, IncludingLast, FirstChar = undefined )
	
	if ( charInRange ( Char, 1040, 1071, true, IncludingLast ) ) then
		FirstChar = Char ( 1040 );
		return true;
	elsif ( charInRange ( Char, 1072, 1103, true, IncludingLast ) ) then
		FirstChar = Char ( 1072 );
		return true;
	else
		return false;
	endif;
	
EndFunction

Function addNumbers ( Object, Prefix, StartNumber = undefined )
	
	exists = true;
	maxCodeLenght = Object.Metadata ().CodeLength;
	codeLenght = StrLen ( Object.Code );
	prefixLenght = StrLen ( Prefix );
	newNumber = ? ( StartNumber = undefined, 1, StartNumber );
	numberLenght = StrLen ( newNumber );
	maxNumberLenght = ? ( StartNumber = undefined, maxCodeLenght, codeLenght ) - prefixLenght;
	if ( prefixLenght = maxCodeLenght ) then
		Object.Code = prefix;
		exists = codeExists ( Object );
	else
		while ( numberLenght <= maxNumberLenght ) do
			newCode = prefix;
			for l = 1 to maxNumberLenght - numberLenght do
				newCode = newCode + "0";
			enddo;
			newCode = newCode + newNumber;
			Object.Code = newCode;
			exists = codeExists ( Object );
			if ( not exists ) then
				break;
			endif;
			newNumber = newNumber + 1;
			numberLenght = StrLen ( newNumber );
		enddo;
	endif;
	return exists;
	
EndFunction
