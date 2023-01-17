jsonrpc_link_notification(integer link, string method, string params_type, list params)
{
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
}

default
{
    state_entry()
    {
        llSetText(llGetObjectName(), <1, 1, 1>, 1);
    }
    
    touch_start(integer total_number)
    {
        jsonrpc_link_notification(LINK_SET, "button-pressed", JSON_OBJECT, ["title", llGetObjectName()]);
    }
}
