string song;
string current_song_request;

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
    link_message(integer sender, integer num, string str, key id)
    {
        string method = llJsonGetValue(str, ["method"]);
        
        if (method == "button-pressed")
        {
            song = llJsonGetValue(str, ["params", "title"]);
            current_song_request = jsonrpc_link_request(LINK_THIS, "pmp:current-song", JSON_OBJECT, [], "");
        }
        else if (llJsonGetValue(str, ["id"]) == current_song_request)
        {
            if (llJsonGetValue(str, ["result"]) == song)
            {
                jsonrpc_link_notification(LINK_THIS, "pmp:stop", JSON_OBJECT, []);
            }
            else
            {
                jsonrpc_link_notification(LINK_THIS, "pmp:play", JSON_OBJECT, ["title", song]);
            }
        }
    }
}
