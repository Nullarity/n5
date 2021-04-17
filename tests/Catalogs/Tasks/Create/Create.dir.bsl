Commando("e1cib/command/Catalog.Tasks.Create");
Set("#Description", _.Description);
if (_.Signature) then
	Click("#Signature");
endif;
Click("#FormWriteAndClose");