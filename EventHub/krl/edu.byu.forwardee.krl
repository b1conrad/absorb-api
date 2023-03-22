ruleset edu.byu.forwardee {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    shares eci, url, since, detail
  }
  global {
    url = function(){ent:url}
    since = function(){ent:since}
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
pre {
  max-width: 80em;
  white-space: pre-wrap;
}
</style>
>>
    detail = function(){
      eid_list = ent:eid_list.defaultsTo([])
      res_list = ent:res_list.defaultsTo([])
      html:header(ent:name,styles)
      + <<<h1>#{ent:name}</h1>
<p>URL: #{ent:url}</p>
<p>Since: #{ent:since.makeMT().ts_format()}</p>
<p>Count: #{ent:fwd_count}</p>
<p>Events forwarded: #{eid_list.length()}</p>
<p>Responses cached: #{res_list.length()}</p>
<table>
<tr>
<th>Event ID</th>
<th>Status</th>
<th>Response</th>
</tr>
#{[eid_list.reverse(),res_list.reverse()]
  .pairwise(function(eid,res){
    status = res.get("status_code")
    message = res.get("status_line")
    <<<tr>
  <td title="#{eid}">#{eid.substr(0,7)}…</td>
  <td><pre>#{status => status + NL + message | "N/A"}</pre></td>
  <td><pre>#{res.encode()}</pre></td>
</tr>
>>}).join("")}</table>
>>
      + html:footer()
    }
    rs_event_domain = "edu_byu_forwardee"
    tags = [rs_event_domain,"ui","forward"]
    eci = function(){
      wrangler:channels(tags).head().get("id")
    }
    makeMT = function(ts){
      MST = time:add(ts,{"hours": -7});
      MDT = time:add(ts,{"hours": -6});
      MDT > "2023-11-05T02" => MST |
      MST > "2023-03-12T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
    cache_limit = 50
    NL = chr(10)
  }
  rule acceptNewURL {
    select when edu_byu_forwardee newURL
      url re#(.*)# setting(url)
    fired {
      ent:url := url
      ent:since := time:now()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    pre {
      chan = wrangler:channels(tags).head()
    }
    if chan.isnull() then
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":rs_event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    always {
      ent:name := wrangler:myself(){"name"}
    }
  }
  rule forwardHiredEvent {
    select when HR_Personal_Action Hired
    pre {
      fwd_count = ent:fwd_count.defaultsTo(0)
      event = event:attrs{"event"}
      event_id = event{["event_header","event_id"]}
      eid_list = ent:eid_list.defaultsTo([]).append(event_id)
      prune = eid_list.length() > cache_limit
    }
    if ent:url then
      http:post(url=ent:url,json=event:attrs,autosend={
        "eci":eci(),"domain":rs_event_domain,
        "type":"post_response","name":"post_response",
      })
    fired {
      ent:fwd_count := fwd_count + 1
      ent:eid_list := prune => eid_list.tail() | eid_list
    }
  }
  rule cacheRecentResponses {
    select when edu_byu_forwardee post_response
    pre {
      res_list = ent:res_list.defaultsTo([]).append(event:attrs)
      prune = res_list.length() > cache_limit
    }
    fired {
      ent:res_list := prune => res_list.tail() | res_list
    }
  }
}
