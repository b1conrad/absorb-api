ruleset edu.byu.forwardee {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    shares url, since, detail
  }
  global {
    url = function(){ent:url}
    since = function(){ent:since}
    detail = function(){
      html:header(ent:name)
      + <<<h1>#{ent:name}</h1>
>>
      + html:footer()
    }
    rs_event_domain = "edu_byu_forwardee"
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
      tags = [rs_event_domain,"ui","forward"]
      chan = wrangler:channels(tags).head()
    }
    if chan.isnull() then
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":rs_event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
  }
}
