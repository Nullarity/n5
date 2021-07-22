// Opens list of sales orders and set filter by memo
StandardProcessing = false;
Commando("e1cib/list/BusinessProcess.Command");
p = Call("Common.Find.Params");
p.Where = "Description";
p.What = _;

Call("Common.Find", p);
