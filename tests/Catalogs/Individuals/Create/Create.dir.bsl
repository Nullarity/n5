// Description:
// Creates a new Individual
//
// Returns:
// Code

Commando ( "e1cib/data/Catalog.Individuals" );

form = With ( "Individuals (cr*" );
name = _.Description;
Set ( "#FirstName", name );
code = Call("Common.GetID");
Set ( "#Code", code );
Click("Yes", "1?:*");
Click ( "#FormWrite" );

idData = _.IDType <> undefined
or _.IDIssued <> undefined
or _.IDIssuedBy <> undefined
or _.IDNumber <> undefined
or _.IDSeries <> undefined;

if ( idData ) then
	Click ( "IDs", GetLinks () );
	With ( "IDs" );
	Click ( "#FormCreate" );
	With ( "Identity Documents (cr*" );
	issued = Format ( _.IDIssued, "DLF=D" );
	Set ( "#Period", issued );
	Set ( "#Type", _.IDType );
	Set ( "#Issued", issued );
	Set ( "#IssuedBy", _.IDIssuedBy );
	Set ( "#Series", _.IDSeries );
	Set ( "#Number", _.IDNumber );
	Click ( "#FormWriteAndClose" );
endif;

Close ( name + "*" );
return code;
