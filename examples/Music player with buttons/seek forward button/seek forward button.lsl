string get_time_request;

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
        llSetText("Seek >>", <1, 1, 1>, 1);
    }
    
    touch_start(integer total_number)
    {
        get_time_request = jsonrpc_link_request(LINK_SET, "pmp:get-time", JSON_OBJECT, [], "");
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if (llJsonGetValue(str, ["id"]) == get_time_request)
        {
            float time = (float) llJsonGetValue(str, ["result"]);
            jsonrpc_link_notification(sender, "pmp:set-time", JSON_OBJECT, ["time", time + 30]);
        }
    }
}
