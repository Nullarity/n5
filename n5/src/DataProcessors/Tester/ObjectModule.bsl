// **************************************************************************************************
// Fluent assertions.
// Ported from https://github.com/wizi4d/xUnitFor1C_2/blob/develop/Plugins/УтвержденияBDD.epf @wizi4d
// Adopted by @JohnyDeath, @Grumagargler
// **************************************************************************************************

Function That ( Something, Message = "" ) export 
	
	Value = Something;
	Details = Message;
	Negation = false;
	return ThisObject;
	
EndFunction

Function Not_ () export
	
	Negation = true;
	return ThisObject;
	
EndFunction

Function Не_ () export
	
	return Not_ ();
	
EndFunction

Function IsTrue () export
	
	if ( wrongResult ( Value = true ) ) then 
		throwError ( valuePresentation ( true ), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function valuePresentation ( Something )
	
	length = undefined;
	type = TypeOf ( Something );
	if ( type = Type ( "Null" )
		or type = Type ( "Undefined" ) ) then
		display = "" + type;
	elsif ( type = Type ( "Boolean" ) ) then
		display = Format ( Something, Output.YesNo () );
	else
		display = "" + Something;
		if ( type = Type ( "Array" )
			or type = Type ( "FixedArray" )
			or type = Type ( "Structure" )
			or type = Type ( "FixedStructure" )
			or type = Type ( "Map" )
			or type = Type ( "FixedMap" )
			or type = Type ( "ValueList" ) ) then
			length = Something.Count ();
		elsif ( type = Type ( "String" ) ) then
			length = StrLen ( String ( Something ) );
		endif;
	endif;
	return display + ? ( length = undefined, "", "[" + Format ( length, "NG=;NZ=" ) + "]" );
	
EndFunction

Function wrongResult ( Result )
	
	wrong = ? ( Negation, Result, not Result );
	if ( wrong ) then
		return true;
	else
		Negation = false;
		return false;
	endif;
	
EndFunction

Procedure throwError ( RightValue, About )
	
	expression = new Array ();
	expression.Add ( displayValue () );
	if ( About = "should" ) then
		verb = ? ( Negation, Output.ShouldNotBe (), Output.ShouldBe () );
	elsif ( About = "contain" ) then
		verb = ? ( Negation, Output.ShouldNotContain (), Output.ShouldContain () );
	elsif ( About = "have" ) then
		verb = ? ( Negation, Output.ShouldNotHave (), Output.ShouldHave () );
	endif;
	expression.Add ( verb );
	expression.Add ( RightValue );
	msg = StrConcat ( expression, " " );
	if ( Details <> "" ) then
		msg = msg + Chars.LF + Details;
	endif;
	raise msg;
	
EndProcedure

Function displayValue ()
	
	return Output.Value () + " " + valuePresentation ( Value );
	
EndFunction

Function ЭтоИстина () export
	
	return IsTrue ();
	
EndFunction

Function IsFalse () export
	
	needed = Value = false;
	if ( wrongResult ( needed ) ) then 
		throwError ( valuePresentation ( needed ), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function ЭтоЛожь () export
	
	return IsFalse ();
	
EndFunction

Function Equal ( Something ) export
	
	if ( wrongResult ( Value = Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Equal );
	endif;
	return ThisObject;
	
EndFunction

Procedure comparisonError ( RightValue, Operator )
	
	expression = new Array ();
	expression.Add ( Lower ( "" + Operator ) );
	expression.Add ( " " + valuePresentation ( RightValue ) );
	throwError ( StrConcat ( expression ), "should" );
	
EndProcedure

Function Равно ( Something ) export
	
	return Equal ( Something );
	
EndFunction

Function NotEqual ( Something ) export
	
	if ( wrongResult ( Value <> Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.NotEqual );
	endif;
	return ThisObject;
	
EndFunction

Function НеРавно ( Something ) export
	
	return NotEqual ( Something );
	
EndFunction

Function Greater ( Something ) export
	
	if ( wrongResult ( Value > Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Greater );
	endif;
	return ThisObject;
	
EndFunction

Function Больше ( Something ) export
	
	return Greater ( Something );
	
EndFunction

Function GreaterOrEqual ( Something ) export
	
	if ( wrongResult ( Value >= Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.GreaterOrEqual );
	endif;
	return ThisObject;
	
EndFunction

Function БольшеИлиРавно ( Something ) export
	
	return GreaterOrEqual ( Something );
	
EndFunction

Function Less ( Something ) export
	
	if ( wrongResult ( Value < Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.Less );
	endif;
	return ThisObject;
	
EndFunction

Function Меньше ( Something ) export
	
	return Less ( Something );
	
EndFunction

Function LessOrEqual ( Something ) export
	
	if ( wrongResult ( Value <= Something )) then 
		comparisonError ( Something, DataCompositionComparisonType.LessOrEqual );
	endif;
	return ThisObject;
	
EndFunction

Function МеньшеИлиРавно ( Something ) export
	
	return LessOrEqual ( Something );
	
EndFunction

Function Filled () export
	
	if ( wrongResult ( ValueIsFilled ( Value ) )) then 
		throwError ( Output.Filled (), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function Заполнено () export
	
	return Filled ();
	
EndFunction

Function Empty () export
	
	if ( wrongResult ( not ValueIsFilled ( Value ) ) ) then 
		throwError ( Output.Empty (), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function Пусто () export
	
	return Empty ();
	
EndFunction

Function Exists () export
	
	needed = ( Value <> undefined ) and ( Value <> null );
	if ( wrongResult ( needed ) ) then 
		throwError ( Output.Existed (), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function Существует () export
	
	return Exists ();
	
EndFunction

Function IsNull () export
	
	if ( wrongResult ( Value = null ) ) then 
		throwError ( null, "should" );
	endif;
	return ThisObject;
	
EndFunction

Function ЭтоNull () export
	
	return IsNull ();
	
EndFunction

Function ЕстьNull () export
	
	return IsNull ();
	
EndFunction

Function IsUndefined () export
	
	if ( wrongResult ( Value = undefined )) then 
		throwError ( undefined, "should" );
	endif;
	return ThisObject;
	
EndFunction

Function ЭтоНеопределено () export
	
	return IsUndefined ();
	
EndFunction

Function Between ( Start, Finish ) export
	
	needed = ( Value >= Start ) and ( Value <= Finish );
	if ( wrongResult ( needed ) ) then 
		throwError ( Output.Between ( new Structure ( "Start, Finish", Start, Finish ) ), "should" );
	endif;
	return ThisObject;
	
EndFunction

Function Между ( Start, Finish ) export
		
	return Between ( Start, Finish );
	
EndFunction

Function Contains ( Something ) export
	
	found = undefined;
	type = TypeOf ( Value );
	if ( type = Type ( "Array" )
		or type = Type ( "FixedArray" ) ) then 
		found = Value.Find ( Something ) <> undefined;
	elsif ( type = Type ( "Structure" )
		or type = Type ( "FixedStructure" )
		or type = Type ( "Map" )
		or type = Type ( "FixedMap" ) ) then 	
		for each item in Value do
			found = ( item.Value = Something );
			if ( found ) then 
				break;
			endif;			
		enddo;		
	elsif ( type = Type ( "ValueList" ) ) then
		found = Value.FindByValue ( Something ) <> undefined;
	else
		found = Find ( String ( Value ), Something ) > 0;
	endif;
	if ( wrongResult ( found = true ) ) then 
		throwError ( Something, "contain" );
	endif;
	return ThisObject;
	
EndFunction

Function Содержит ( Something ) export
	
	return Contains ( Something );
	
EndFunction

Function Has ( Size ) export
	
	type = TypeOf ( Value );
	if ( type = Type ( "Array" )
		or type = Type ( "FixedArray" )
		or type = Type ( "Structure" )
		or type = Type ( "FixedStructure" )
		or type = Type ( "Map" )
		or type = Type ( "FixedMap" )
		or type = Type ( "ValueList" ) ) then
		length = Value.Count ();					
	else
		length = StrLen ( String ( Value ) );
	endif;
	if ( wrongResult ( length = Size )) then 
		throwError ( Size, "have" );
	endif;
	return ThisObject;
	
EndFunction

Function ИмеетДлину ( Size ) export
	
	return Has ( Size );
	
EndFunction

Function Вмещает ( Size ) export
	
	return Has ( Size );
	
EndFunction
