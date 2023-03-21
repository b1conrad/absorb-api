ruleset code-repo {
  meta {
    use module io.picolabs.wrangler alias wrangler
    shares code
  }
  global {
    code = function(rid){
      ent:code.get(rid) || "ruleset "+rid+" {}"
    }
    tags = ["code-repo"]
    rs_event_domain = "code_repo"
  }
  rule stashCode {
    select when code_repo new_ruleset
      rid re#(^\w[\w\d-]+)$# setting(rid)
    fired {
      ent:code{rid} := event:attrs{"krl"}
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attrs{"rids"} >< meta:rid
    pre {
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
