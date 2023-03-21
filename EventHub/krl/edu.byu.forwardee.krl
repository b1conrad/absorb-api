ruleset edu.byu.forwardee {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    shares eci, url, since, detail
  }
  global {
    url = function(){ent:url}
    since = function(){ent:since}
    detail = function(){
      html:header(ent:name)
      + <<<h1>#{ent:name}</h1>
<p>URL: #{ent:url}</p>
<p>Since: #{ent:since.makeMT().ts_format()}</p>
<p>Count: #{ent:fwd_count}</p>
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
    }
    if ent:url then
      http:post(url=ent:url,json=event:attrs,autosend={
        "eci":eci(),"domain":rs_event_domain,
        "type":"post_response","name":"post_response",
      })
    fired {
      ent:fwd_count := fwd_count + 1
    }
  }
}
