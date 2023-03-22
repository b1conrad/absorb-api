ruleset code-repo {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module html
    shares code, repo
  }
  global {
    code = function(rid){
      ent:code >< rid      => ent:code.get(rid) |
      rid.match(valid_rid) => "ruleset "+rid+" {}" |
                              ""
    }
    tags = ["code-repo"]
    rs_event_domain = "code_repo"
    valid_rid = re#(^\w[\w\d-.]+)$#
    repo = function(){
      base_url = <<#{meta:host}/c/#{meta:eci}/query/#{meta:rid}/code.txt?rid=>>
      html:header("Repo")
      + <<<h1>Repo</h1>
<ul>
#{ent:code.map(function(v,k){
  <<<li>#{k} <a href="#{base_url+k}">raw</a></li>
>>
}).values().join("")}</ul>
>>
      + html:footer()
    }
  }
  rule stashCode {
    select when code_repo new_ruleset
      rid re#(^\w[\w\d-.]+)$# setting(rid)
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
