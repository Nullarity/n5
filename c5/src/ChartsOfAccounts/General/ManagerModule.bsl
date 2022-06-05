#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

Procedure PresentationFieldsGetProcessing ( Fields, StandardProcessing )
	
	StandardProcessing = false;
	Fields.Add ( ? ( Application.AccountsName (), getDescription (), "Code" ) );
	
EndProcedure

Function getDescription ( ScriptEnglish = true ) 

	return ? ( Options.Russian (), "DescriptionRu", ? ( ScriptEnglish, "Description", "Наименование" ) );

EndFunction

Procedure PresentationGetProcessing ( Data, Presentation, StandardProcessing )
	
	StandardProcessing = false;
	showName = Application.AccountsName ();
	if ( Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English ) then
		Presentation = ? ( showName, Data [ getDescription () ], Data.Code );
	else
		Presentation = ? ( showName, Data [ getDescription ( false ) ], Data.Код );
	endif; 
	
EndProcedure

Procedure ChoiceDataGetProcessing ( ChoiceData, Parameters, StandardProcessing )
	
	if ( Options.Russian () ) then
		StandardProcessing = false;
		fill ( ChoiceData, Parameters );
	endif;	
	
EndProcedure

Procedure fill ( ChoiceData, Parameters )
	
	ChoiceData = new ValueList ();
	search = new FormattedString ( Parameters.SearchString, new Font ( , , true ), new Color ( 0, 154, 0 ) );
	accounts = findAccounts ( Parameters );
	for each item in accounts do
		presentation = new FormattedString ( search, item.Code + " (" + item.Description + ")" );
		ChoiceData.Add ( item.Ref, presentation );
	enddo; 
	
EndProcedure 

Function findAccounts ( Parameters )
	
	codeLen = Metadata.ChartsOfAccounts.General.StandardAttributes.Code.Type.StringQualifiers.Length;
	q = new Query ();
	s = "
	|select top 10 Accounts.DescriptionRu as Description, Accounts.Ref as Ref,
	|	substring ( Accounts.Code, " + StrLen ( Parameters.SearchString + 1 ) + ", " + codeLen + " ) as Code
	|from ChartOfAccounts.General as Accounts
	|where not Accounts.DeletionMark
	|and Accounts.Code like &Code
	|";
	typeArray = Type ( "FixedArray" );
	typeList = Type ( "ValueList" );
	for each item in Parameters.Filter do
		value = item.Value;
		name = item.Key;
		valueType = TypeOf ( value );
		if ( valueType = typeArray
			or valueType = typeList ) then
			condition = " in ( &" + name + " )";
		else
			condition = " = &" + name;
		endif;
		q.SetParameter ( name, value );
		s = s + "
		|and Accounts." + name + condition;
	enddo;
	s = s + "
	|order by Accounts.Order
	|";
	q.Text = s;
	q.SetParameter ( "Code", Parameters.SearchString + "%" );
	return q.Execute ().Unload ();
	
EndFunction 

#endif
