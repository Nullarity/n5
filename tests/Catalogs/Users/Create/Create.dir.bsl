Commando ( "e1cib/command/Catalog.Users.Create" );

// Fill profile
Set ( "#Description", _.Name );
Set ( "#Code", _.Code );
Set ( "#Email",  _.Code + "@wsxcderfv.xxx" );
Set ( "#Language", _.Language );
Set ( "#Department", _.Department );
Set ( "#Warehouse", _.Warehouse );
Click("#MustChangePassword");
Activate ( "Access" );

// Set Restrictins
list = _.Organizations;
if ( _.Organizations.Count () > 0 ) then
	Pick ( "#OrganizationAccess", "Allow Access to the Catalog Values" );
	Organizations = Get ( "#Organizations" );
	for each item in list do
		Click ( "#OrganizationsAdd" );
		Organizations.EndEditRow ();
		Set ( "#OrganizationsOrganization", item, Organizations );
	enddo;
endif;

Click("#MembershipUnmarkAllGroups");
Click ( "#RightsEditRights" );

// Set rights
With ();
Rights = Get ( "#Rights" );
for each set in _.Rights do
	Rights.GotoFirstRow ();
	for each right in Conversion.StringToArray ( set, ";" ) do
		pair = Conversion.StringToArray ( right, "/" );
		search = new Map ();
		search [ "Right" ] = pair [ 0 ];
		if ( Rights.GotoRow ( search ) ) then
			if ( not Rights.Expanded () ) then
				Rights.Expand ();
			endif;
		endif;
		search = new Map ();
		search [ "Right" ] = pair [ 1 ];
		search [ "Use" ] = "No";
		if ( Rights.GotoRow ( search ) ) then
			Rights.ChangeRow ();
			Get ( "#RightsUse" ).SetCheck ();
			try
				Click ( "#RightsApplyRights" );
			except
			endtry;
		endif;
	enddo;
enddo;

// Commit changes
Click ( "#Commit" );
With();
Click("#FormWriteAndClose");
Pause ( 3 * __.Performance );