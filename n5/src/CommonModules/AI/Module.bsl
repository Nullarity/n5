Function BuildOrganizationName ( Name, SecondAttempt = false ) export

	p = new Structure ( "Name, Notes", Name, "" );
	system = "
	|You are an assistant responsible for entering customer information into accounting software in Moldova.
	|Given a customer name from user input, return a JSON object containing the cleaned and standardized short and full names of the customer, following these rules:
	|
	|1. Remove all legal entity types (SRL, LLC, LTD, II, SC, INC, SA, GT, etc.) for the short name.
	|2. Properly capitalize both names (first letter of each word capitalized).
	|3. Remove unnecessary punctuation unless it's part of the actual customer name.
	|4. Preserve special characters that are part of the brand name.
	|5. Abbreviate the legal entity types in the full name. Do not use unnecessary punctuation in the abbreviations.
	|6. Always put the legal entity type after the customer name in the full name.
	|7. When you build a short name, take users' notes into consideration if specified.
	|8. Return result as a valid JSON object.
	|9. DO NOT include explanations, assumptions, or formatting, and keep the JSON expected output format consistent.
	|
	|<expected_output>
	|{""short_name"":""<cleaned short name>"",""full_name"":""<cleaned full name>""}
	|</expected_output>
	|";
	user = "
	|<user_input>
	|%Name
	|</user_input>
	|%Notes
	|";
	if ( SecondAttempt ) then
		p.Notes = "
		|
		|<user_notes>
		|Please note that the database already contains a customer with a similar short name. Therefore, make the short name of the new customer slightly different to avoid duplicates. For example, you can use some parts of the full name (a full name is always unique).
		|</user_notes>
		|";
	endif;
	system = Output.FormatStr ( system, p );
	user = Output.FormatStr ( user, p );
	return AIServer.Ask ( AIServer.QuestionParams ( user, system ) );

EndFunction

Function AddressInfo ( String, Alien = false ) export

	system = "
	|You are an assistant responsible for entering customer information into accounting software in Moldova. Given an arbitrary address string from user input, please return a JSON object containing the cleaned and standardized address components, following these rules:
	|
	|- Fill in only the fields you can extract from the given string.
	|- Extract components in Romanian language, but don't use special Romanian characters.
	|- Properly capitalize all names.";
	if ( Alien ) then
		system = system + "
		|- If the country is not specified in the given address, then try to detect it.";
	endif;
	system = system + "
	|- DO NOT include explanations, assumptions, or formatting, and keep the JSON expected output format consistent.
	|
	|<expected_output>
	|{
	|  ""street_name"": ""<street name>"",
	|  ""street_number"": ""<street number>"",
	|  ""building"": ""<building number>"",
	|  ""entrance"": ""<entrance number>"",
	|  ""floor"": ""<floor number>"",
	|  ""apartment"": ""<apartment number>"",
	|  ""locality_name"": ""<name of city, town, or village>"",
	|  ""locality_is_village"": ""<boolean value; true if the locality is a village, and false otherwise>"",
	|  ""sector"": ""<name of sector: larger cities like Chisinau are divided into sectors (e.g., Centru, Botanica, Riscani, Buiucani, Ciocana), which can be added for more specificity>"",
	|  ""raion"": ""<raion, district, province, or state>"",
	|  ""country"": """ + ? ( Alien, "<country name>", "<Moldova, by default>" ) + """
	|  ""postal_code"": ""<postal code>""
	|}
	|</expected_output>
	|";
	user = "
	|<user_input>
	|" + String + "
	|</user_input>
	|";
	return AIServer.Ask ( AIServer.QuestionParams ( user, system ) );

EndFunction

Function Translate ( String, Tip, Direction = "Romanian to Russian" ) export

	system = "You are a professional translator.";
	user = "Please translate the following text";
	if ( Tip <> "" ) then
		user = user + " (" + Tip + " )";
	endif;
	user = user + " from " + Direction + ". Provide only the translation without any additional explanations, notes, or commentary.
	|<text_to_translate>
	|" + String + "
	|</text_to_translate>";
	return AIServer.Ask ( AIServer.QuestionParams ( user, system ), false );

EndFunction

Function FindCountry ( Name, Top = undefined ) export
	
	p = findLocalityParams ( "countries", Name, Top, "" );
	return findInTable ( p );
	
EndFunction

Function findLocalityParams ( Table, Name, Top, Country )
	
	p = new Structure ( "Table, Name, Top, Country",
		Table, Name, Top, Country );
	return p;
	
EndFunction

Function findInTable ( Params ) export
	
	result = new Array ();
	top = Params.Top;
	askingAssistant = top <> undefined;
	table = Params.Table;
	name = Params.Name;
	similarities = fetchSimilarities ( name, table );
	if ( similarities.Count () = 0 ) then
	elsif ( similarities [ 0 ].Distance >= 0.9 ) then
		result.Add ( Catalogs [ table ].GetRef ( new UUID ( similarities [ 0 ].ID ) ) );
	else
		hasCyrillic = CoreLibrary.HasCyrillic ( name );
		list = listOf ( table, similarities, hasCyrillic );
		fuzzyList = fuzzyMatch ( table, name, hasCyrillic, list );
		if ( fuzzyList [ 0 ].score >= 0.8 ) then
			result.Add ( Catalogs [ table ].FindByCode ( fuzzyList [ 0 ].id ) );
		elsif ( askingAssistant ) then
			codes = determine ( list, Params );
			if ( codes <> undefined and codes.Count () > 0 ) then
				q = new Query ( "
				|select Ref as Ref
				|from Catalog." + table
				+ " where Code in ( &Codes )
				|order by Description" );
				q.SetParameter ( "Codes", codes );
				result = q.Execute ().Unload ().UnloadColumn ( "Ref" );
			endif;
		endif;
	endif;
	return ? ( result = undefined or result.Count () = 0, undefined, result );
	
EndFunction

Function fetchSimilarities ( ForText, Table )
	
	limit = 10;
	result = resultTable ();
	if ( Table = "countries" ) then
		inRussian = CoreLibrary.HasCyrillic ( ForText );
		if ( inRussian ) then
			textRu = ForText;
			text = "";
			column = "vectorRu";
		else
			textRu = "";
			text = ForText;
			column = "vector";
		endif;
		vector = AIServer.GetVectors ( text, textRu, Table, true ) [ column ];
		addResult ( result, AIServer.FindRows ( Table, vector, column, limit ) );
	else
		vectors = AIServer.GetVectors ( ForText, , Table, true );
		addResult ( result, AIServer.FindRows ( Table, vectors.vector, "vector", limit ) );
		addResult ( result, AIServer.FindRows ( Table, vectors.vectorRu, "vectorRu", limit ) );
		result.Sort ( "Distance desc" );
	endif;
	return result;
	
EndFunction

Function resultTable ()

	table = new ValueTable ();
	columns = table.Columns;
	columns.Add ( "ID", new TypeDescription ( "String" ) );
	columns.Add ( "Distance", new TypeDescription ( "Number" ) );
	return table;

EndFunction

Procedure addResult ( Result, Similarities )

	for each entry in Similarities do
		id = entry.id;
		distance = entry.distance;
		found = Result.Find ( id );
		if ( found = undefined ) then
			row = result.Add ();
			row.ID = id;
			row.Distance = distance;
		elsif ( found.Distance < distance ) then
			found.Distance = distance;
		endif;
	enddo;

EndProcedure

Function listOf ( Table, Similarities, InRussian )
	
	if ( table = "countries" ) then
		s = "
		|select List.Code as Code, List."
		+ ? ( InRussian, "DescriptionRu", "Description" ) + " as Name
		|from Catalog.Countries as List
		|where not List.DeletionMark
		|and List.Ref in ( &List )
		|order by Name
		|";
	else
		s = "
		|select List.Code as Code, List.Description as Name
		|from Catalog." + Table + " as List
		|where not List.DeletionMark
		|and List.Ref in ( &List )
		|order by Name
		|";
	endif;
	list = new Array ();
	for each entry in Similarities do
		list.Add ( Catalogs [ Table ].GetRef ( new UUID ( entry.ID ) ) );
	enddo;
	q = new Query ( s );
	q.SetParameter ( "List", list );
	data = q.Execute ().Unload ();
	result = new Array ();
	for each row in data do
		result.Add ( new Structure ( "id, name", row.Code, row.Name ) );
	enddo;
	return result;
	
EndFunction

Function fuzzyMatch ( Table, val Name, HasCyrillic, List )
	
	if ( HasCyrillic and Table <> "countries" ) then
		Name = CoreLibrary.CyrillicToRomanian ( Name );
	endif;
	return CoreLibrary.FuzzyMatch ( List, "name", Name );
	
EndFunction

Function determine ( List, Params )

	table = Params.Table;
	if ( table = "countries" ) then
		user = "
		|A user is entering data into the accounting system using voice commands. Your task is to identify the country that the user intended based on their spoken input.
		|
    |Instructions:
		|
		|- Consider the user’s spoken input and find the best matching countries from the provided list.
		|- Return a JSON array of up to %Top country IDs from the list that most closely match the user’s input.
		|- Only return results if you are certain the user’s input corresponds to an actual country in the list. Avoid selecting countries based solely on partial or superficial name similarity.
		|- If no exact match or recognized variant is found in the list, return an empty JSON array.
		|- DO NOT include explanations, assumptions, or formatting, and keep the JSON expected output format consistent.
		|
		|<list_of_countries>
		|%List
		|</list_of_countries>
		|
		|<user_input>
		|%Name
		|</user_input>
 		|
		|Expected output is an JSON array of strings where each string is the ID of an identified country.
		|
		|<expected_output>
		|[
		|  ""004"",
		|  ""123"",
		|  ""007""
		|]
		|</expected_output>
		|";
	elsif ( table = "states" ) then
		user = "
		|A user is entering data into the accounting system using voice commands. Your task is to identify the state (district, raion) in %Country that the user intended based on their spoken input.
		|
    |Instructions:
		|
		|- Consider the user’s spoken input and find the best matching states (district, raions) from the provided list.
		|- Return a JSON array of up to %Top state (district, raion) IDs from the list that most closely match the user’s input.
		|- Only return results if you are certain the user’s input corresponds to an actual state (district, raion) in the list. Avoid selecting states (districts, raions) based solely on partial or superficial name similarity.
		|- If no exact match or recognized variant is found in the list, return an empty JSON array.
		|- DO NOT include explanations, assumptions, or formatting, and keep the JSON expected output format consistent.
		|
		|<list_of_states_or_raions>
		|%List
		|</list_of_states_or_raions>
		|
		|<user_input>
		|%Name
		|</user_input>
 		|
		|Expected output is an JSON array of strings where each string is the ID of an identified state (district, raion).
		|
		|<expected_output>
		|[
		|  ""00004"",
		|  ""02123"",
		|  ""00007""
		|]
		|</expected_output>
		|";
	elsif ( table = "cities" ) then
		user = "
		|A user is entering data into the accounting system using voice commands. Your task is to identify the locality (city, town, or village) in %Country that the user intended based on their spoken input.
		|
    |Instructions:
		|
		|- Consider the user’s spoken input and find the best matching localities from the provided list.
		|- Return a JSON array of up to %Top locality IDs from the list that most closely match the user’s input.
		|- Only return results if you are certain the user’s input corresponds to an actual locality in the list. Avoid selecting localities based solely on partial or superficial name similarity.
		|- If no exact match or recognized variant is found in the list, return an empty JSON array.
		|- DO NOT include explanations, assumptions, or formatting, and keep the JSON expected output format consistent.
		|
		|<list_of_localities>
		|%List
		|</list_of_localities>
		|
		|<user_input>
		|%Name
		|</user_input>
 		|
		|Expected output is an JSON array of strings where each string is the ID of an identified locality.
		|
		|<expected_output>
		|[
		|  ""000044578"",
		|  ""648702123"",
		|  ""RT0400007""
		|]
		|</expected_output>
		|";
	endif;
	p = Collections.CopyStructure ( Params );
	p.Insert ( "List", Conversion.ToJSON ( List ) );
	return AIServer.Ask ( AIServer.QuestionParams ( Output.FormatStr ( user, p ) ) );

EndFunction

Function FindState ( Name, Country, Top = undefined ) export
	
	p = findLocalityParams ( "states", Name, Top, Country );
	return findInTable ( p );
	
EndFunction

Function FindCity ( Name, Country, Top = undefined ) export
	
	p = findLocalityParams ( "cities", Name, Top, Country );
	return findInTable ( p );
	
EndFunction
