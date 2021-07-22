// Opens list of sales orders and set filter by memo
StandardProcessing = false;
Commando("e1cib/list/Task.UserTask");
p = Call("Common.Find.Params");
p.Where = "Command";
p.What = _;

Call("Common.Find", p);
