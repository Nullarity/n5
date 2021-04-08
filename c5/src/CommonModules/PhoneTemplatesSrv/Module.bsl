
Function GetList () export
	
	s = "
	|select Phones.Mask as Mask, Phones.Description as Description
	|from Catalog.Phones as Phones
	|where not Phones.DeletionMark
	|order by Phones.Description
	|";
	q = new Query ( s );
	table = q.Execute ().Unload ();
	list = new ValueList ();
	for each row in table do
		list.Add ( row.Mask, row.Description );
	enddo; 
	return list;
	
EndFunction 

Function PickMask ( Phone, Templates ) export

	alphabet = "qwertyuiopasdfghjklzxcvbnmёйцукенгшщзхъфывапролджэячсмитьбю";
	ABCs = Upper ( alphabet );
	numbers = "0123456789";
	special = "!9#NUX@";
	space = " ";
	plusminus = "+-";
	phoneSize = StrLen ( Phone );
	for each item in Templates do
		mask = item.Value;
		maskSize = StrLen ( Mask );
		if ( maskSize < phoneSize ) then
			continue;
		endif;
		match = true;
		checkTemplate = true;
		i = 0;
		j = 0;
		size = max ( maskSize, phoneSize );
		while ( i < size ) do
			i = i + 1;
			template = Mid ( Mask, i, 1 );
			if ( template = "\" ) then
				checkTemplate = false;
				continue;
			endif; 
			j = j + 1;
			letter = Mid ( Phone, j, 1 );
			if ( checkTemplate ) then
				match =
				( template = "!" and inList ( letter, ABCs ) )
				or ( template = "9" and inList ( letter, numbers ) )
				or ( template = "#" and inList ( letter, numbers, plusminus, space ) )
				or ( template = "N" and inList ( letter, alphabet, ABCs, numbers ) )
				or ( template = "U" and inList ( letter, ABCs, numbers ) )
				or ( template = "X" and letter <> "" )
				or ( template = "@" and inList ( letter, ABCs, numbers, space ) )
				or ( template = letter and not inList ( template, special ) );
			else
				match = letter = template;
			endif; 
			if ( not match ) then
				break;
			endif; 
			checkTemplate = true;
		enddo;
		if ( match ) then
			return mask;
		endif; 
	enddo; 
	return undefined;
	
EndFunction

Function inList ( Letter, Set1, Set2 = undefined, Set3 = undefined, Set4 = undefined )
	
	return StrFind ( Set1, Letter ) > 0
	or ( Set2 <> undefined and StrFind ( Set2, Letter ) > 0 )
	or ( Set3 <> undefined and StrFind ( Set3, Letter ) > 0 )
	or ( Set4 <> undefined and StrFind ( Set4, Letter ) > 0 );
	
EndFunction 

Function GetMenu () export
	
	list = PhoneTemplatesSrv.GetList ();
	if ( AccessRight ( "Edit", Metadata.Catalogs.Phones ) ) then
		list.Add ( Enum.PhonesActionsNew (), Output.NewPhoneTemplate (), , PictureLib.CreateListItem );
		list.Add ( Enum.PhonesActionsList (), Output.ListPhoneTemplates (), , PictureLib.Catalog );
	endif; 
	return list;
	
EndFunction 
