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

key get_volume_request;

default
{
    state_entry()
    {
        llSetText("Vol -", <1, 1, 1>, 1);
    }

    touch_start(integer total_number)
    {
        get_volume_request = jsonrpc_link_request(LINK_SET, "pmp:get-volume", JSON_OBJECT, [], "");
    }
    
    link_message(integer sender, integer num, string str, key id)
    {
        if (llJsonGetValue(str, ["id"]) == get_volume_request)
        {
            float volume = (float) llJsonGetValue(str, ["result"]);
            jsonrpc_link_notification(sender, "pmp:set-volume", JSON_OBJECT, ["volume", volume - .1]);
        }
    }
}
