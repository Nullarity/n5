#if ( Server or ThickClientOrdinaryApplication or ExternalConnection ) then

var String export;
var Alien export;
var Address;
var Object;

Function Get () export

	Object = Catalogs.Addresses.CreateItem ();
	Address = AI.AddressInfo ( CoreLibrary.RomanianToLatin ( String ), Alien );
	Object.Street = Collections.Value ( Address, "street_name", "" );
	Object.Number = Collections.Value ( Address, "street_number", "" );
	Object.Building = Collections.Value ( Address, "building", "" );
	Object.Entrance = Collections.Value ( Address, "entrance", "" );
	Object.Floor = Collections.Value ( Address, "floor", "");
	Object.Apartment = Collections.Value ( Address, "apartment", "" );
	Object.ZIP = Collections.Value ( Address, "postal_code", "" );
	determineCountry ();
	determineState ();
	determineCity ();
	ContactsForm.SetAddress ( Object );
	Object.Description = StrReplace ( Object.Address, Chars.LF, ", " );
	return Object;

EndFunction

Procedure determineCountry ()

	name = Collections.Value ( Address, "country", "Moldova" );
	ref = Catalogs.Countries.FindByDescription ( name, true );
	if ( ref.IsEmpty () ) then
		found = AI.FindCountry ( name );
		if ( found = undefined ) then
			obj = Catalogs.Countries.CreateItem ();
			obj.Description = name;
			obj.DescriptionRu = AI.Translate ( name, "country name" );
			obj.Write ();
			ref = obj.Ref;
		else
			ref = found [ 0 ];
		endif;
	endif;
	Object.Country = ref;

EndProcedure

Procedure determineState ()

	name = Collections.Value ( Address, "raion", "" );
	if ( IsBlankString ( name ) ) then
		Object.State = undefined;
		return;
	endif;
	country = Object.Country;
	ref = Catalogs.States.FindByDescription ( name, true, , country );
	if ( ref.IsEmpty () ) then
			found = AI.FindState ( name, country );
			ref = ? ( found = undefined, undefined, found [ 0 ] );
		if ( ref <> undefined
			and ref.Owner <> country ) then
			ref = Catalogs.States.FindByDescription ( ref.Description, true, , country );
		endif;
		if ( not ValueIsFilled ( ref ) ) then
			obj = Catalogs.States.CreateItem ();
			obj.Owner = country;
			obj.Description = Name;
			obj.Write ();
			ref = obj.Ref;
		endif;
	endif;
	Object.State = ref;

EndProcedure

Procedure determineCity ()

	name = Collections.Value ( Address, "locality_name", "" );
	if ( IsBlankString ( name ) ) then
		Object.City = undefined;
		return;
	endif;
	isVillage = Collections.Value ( Address, "locality_is_village", false, Type ( "Boolean" ) );
	if ( isVillage ) then
		name = Output.VillagePrefix () + name;
	endif;
	country = Object.Country;
	state = Object.State;
	ref = Catalogs.Cities.FindByDescription ( name, true, , country );
	if ( ref.IsEmpty () ) then
		ref = Catalogs.Cities.FindByDescription ( name, true, , state );
		if ( ref.IsEmpty () ) then
			found = AI.FindCity ( name, country );
			ref = ? ( found = undefined, undefined, found [ 0 ] );
			if ( ref <> undefined
				and ( ref.Owner <> country and ref.Owner <> state ) ) then
				ref = Catalogs.Cities.FindByDescription ( ref.Description, true, , country );
			endif;
			if ( not ValueIsFilled ( ref ) ) then
				obj = Catalogs.Cities.CreateItem ();
				obj.Owner = ? ( state.IsEmpty (), country, state );
				obj.Description = name;
				obj.Write ();
				ref = obj.Ref;
			endif;
		endif;
	endif;
	Object.City = ref;

EndProcedure

#endif