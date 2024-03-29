/* pmp helper functions */
jsonrpc_link_notification(integer link, string method, string params_type, list params)
{
    llMessageLinked(link, 0, llList2Json(JSON_OBJECT, ["jsonrpc", "2.0", "method", method, "params", llList2Json(params_type, params)]), NULL_KEY);
}

pmp_play(integer link, string title, integer loop, float volume)
{
    jsonrpc_link_notification(link, "pmp:play", JSON_OBJECT, ["title", title, "loop", loop, "volume", volume]);
}

pmp_stop(integer link)
{
    jsonrpc_link_notification(link, "pmp:stop", JSON_OBJECT, []);
}
 
pmp_pause(integer link)
{
    jsonrpc_link_notification(link, "pmp:pause", JSON_OBJECT, []);
}

pmp_resume(integer link)
{
    jsonrpc_link_notification(link, "pmp:resume", JSON_OBJECT, []);
}
 
pmp_set_volume(integer link, float volume)
{
    jsonrpc_link_notification(link, "pmp:set-volume", JSON_OBJECT, ["volume", volume]);
}

pmp_set_time(integer link, float time)
{
    jsonrpc_link_notification(link, "pmp:set-time", JSON_OBJECT, ["time", time]);
}
