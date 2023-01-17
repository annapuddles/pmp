string is_paused_request;

string jsonrpc_link_request(integer link, string method, string params_type, list params, string id)
{
    if (id == "") id = (string) llGenerateKey();
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "id", id, "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
    return id;
}

jsonrpc_link_notification(integer link, string method, string params_type, list params)
{
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
}

default
{
    state_entry()
    {
        llSetText("Pause", <1, 1, 1>, 1);
    }

    touch_start(integer total_number)
    {
        is_paused_request = jsonrpc_link_request(LINK_SET, "pmp:is-paused", JSON_OBJECT, [], "");
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if (llJsonGetValue(str, ["id"]) == is_paused_request)
        {
            if (llJsonGetValue(str, ["result"]) == "1")
            {
                jsonrpc_link_notification(sender, "pmp:resume", JSON_OBJECT, []);
            }
            else
            {
                jsonrpc_link_notification(sender, "pmp:pause", JSON_OBJECT, []);
            }
        }
    }
}
