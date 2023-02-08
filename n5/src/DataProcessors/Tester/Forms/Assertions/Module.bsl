&AtClient
Function That ( CheckVal, Message = "" ) export 
	
	runMethod ( "That", 2, CheckVal, Message );
	return ThisObject;
	
EndFunction

&AtServer
Procedure runMethod ( val Method, val Agruments, val P1 = undefined, val P2 = undefined )
	
	p = new Array ();
	for i = 1 to Agruments do
		p.Add ( "P" + Format ( i, "NG=" ) );
	enddo;
	obj = FormAttributeToValue ( "Object" );
	Execute ( "obj." + Method + "( " + StrConcat ( p, "," ) + " )" );
	ValueToFormAttribute ( obj, "Object" );
	
EndProcedure

&AtClient
Function Not_ () export
	
	runMethod ( "Not_", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function Не_ () export
	
	return Not_ ();
	
EndFunction

&AtClient
Function IsTrue () export 
	
	runMethod ( "IsTrue", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function ЭтоИстина () export
	
	return IsTrue ();
	
EndFunction

&AtClient
Function IsFalse () export 
	
	runMethod ( "IsFalse", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function ЭтоЛожь () export
	
	return IsFalse ();
	
EndFunction

&AtClient
Function Equal ( Value ) export 
	
	runMethod ( "Equal", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function Равно ( Value ) export
	
	return Equal ( Value );
	
EndFunction

&AtClient
Function NotEqual ( Value ) export 
	
	runMethod ( "NotEqual", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function НеРавно ( Value ) export
	
	return NotEqual ( Value );
	
EndFunction

&AtClient
Function Greater ( Value ) export 
	
	runMethod ( "Greater", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function Больше ( Value ) export
	
	return Greater ( Value );
	
EndFunction

&AtClient
Function GreaterOrEqual ( Value ) export 
	
	runMethod ( "GreaterOrEqual", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function БольшеИлиРавно ( Value ) export
	
	return GreaterOrEqual ( Value );
	
EndFunction

&AtClient
Function Less ( Value ) export 
	
	runMethod ( "Less", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function Меньше ( Value ) export
	
	return Less ( Value );
	
EndFunction

&AtClient
Function LessOrEqual ( Value ) export 
	
	runMethod ( "LessOrEqual", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function МеньшеИлиРавно ( Value ) export
	
	return LessOrEqual ( Value );
	
EndFunction

&AtClient
Function Filled () export 
	
	runMethod ( "Filled", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function Заполнено () export
	
	return Filled ();
	
EndFunction

&AtClient
Function Empty () export 
	
	runMethod ( "Empty", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function Пусто () export
	
	return Empty ();
	
EndFunction

&AtClient
Function Exists () export 
	
	runMethod ( "Exists", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function Существует () export
	
	return Exists ();
	
EndFunction

&AtClient
Function IsNull () export 
	
	runMethod ( "IsNull", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function ЭтоNull () export
	
	return IsNull ();
	
EndFunction

&AtClient
Function ЕстьNull () export
	
	return IsNull ();
	
EndFunction

&AtClient
Function IsUndefined () export 
	
	runMethod ( "IsUndefined", 0 );
	return ThisObject;
	
EndFunction

&AtClient
Function ЭтоНеопределено () export
	
	return IsUndefined ();
	
EndFunction

&AtClient
Function Between ( Start, Finish ) export 
	
	runMethod ( "Between", 2, Start, Finish );
	return ThisObject;
	
EndFunction

&AtClient
Function Между ( Start, Finish ) export
	
	return Between ( Start, Finish );
	
EndFunction

&AtClient
Function Contains ( Value ) export 
	
	runMethod ( "Contains", 1, Value );
	return ThisObject;
	
EndFunction

&AtClient
Function Содержит ( Value ) export
	
	return Contains ( Value );
	
EndFunction

&AtClient
Function Has ( Size ) export 
	
	runMethod ( "Has", 1, Size );
	return ThisObject;
	
EndFunction

&AtClient
Function ИмеетДлину ( Size ) export
	
	return Has ( Size );
	
EndFunction

&AtClient
Function Вмещает ( Size ) export
	
	return Has ( Size );
	
EndFunction
