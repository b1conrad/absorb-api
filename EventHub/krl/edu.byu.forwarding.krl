ruleset edu.byu.forwarding {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    shares forward
  }
  global {
    rs_event_domain = "edu_byu_forwarding"
    styles = <<<style type="text/css">
table {
  border: 1px solid black;
  border-collapse: collapse;
}
td, th {
  border: 1px solid black;
  padding: 5px;
}
input.wide90 {
  width: 40em;
}
</style>
>>
    forward = function(){
      base_url = <<#{meta:host}/sky/event/#{meta:eci}/none/#{rs_event_domain}>>
      url = base_url + "/forwarding_requested"
      delr = function(m){
        del_url = base_url + "/forwarding_deletion_requested?name="
        <<<a href="#{del_url+m{"name"}}">del</a\>>>
      }
      js1 = function(to){
        "document.getElementById('forward_" + to + "').value = this.value"
      }
      js2 = function(){
        "document.getElementById('forward_form').submit()"
      }
      html:header("Forwarding",styles)
      + <<<h1>Forwarding</h1>
<table>
<tr>
  <th>name</th>
  <th>url</th>
  <th>op</th>
</tr>
#{wrangler:children().map(function(v){
  child_rid = "edu.byu.forwardee"
  fam_eci = v{"eci"}
  has_rid = wrangler:picoQuery(fam_eci,"io.picolabs.wrangler","installedRIDs") >< child_rid
  child_url = has_rid => wrangler:picoQuery(fam_eci,child_rid,"url")
                       | "N/A"
  child_eci = has_rid => wrangler:picoQuery(fam_eci,child_rid,"eci")
                       | null
  detail_url = <<#{meta:host}/c/#{child_eci}/query/#{child_rid}/detail.html>>
  disable = has_rid => "" | " disabled"
  detr = function(name){
    <<<a href="#{detail_url}" target="_blank"#{disable}>#{name}</a\>>>
  }
  <<<tr>
  <td>#{detr(v{"name"})}</td>
  <td>#{child_url}</td>
  <td>#{delr(v)}</td>
</tr>
>>}).join("")}
<tr>
<td><input onchange="#{js1("name")}" required placeholder="name"></td>
<td><input onchange="#{js1("url")}" required class="wide90" placeholder="url"></td>
<td><button onclick="#{js2()}">add</button> <sup>*</sup></td>
</td></tr>
</table>
<form id="forward_form" action="#{url}">
<input id="forward_name" name="name" type="hidden">
<input id="forward_url" name="url" type="hidden">
</form>
<p><sup>*</sup> This user experience is not fully self-service. Some manual work required.</p>
>>
      + html:footer()
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    pre {
      tags = [rs_event_domain,"ui"]
      chan = wrangler:channels(tags).head()
    }
    if chan.isnull() then
      wrangler:createChannel(
        tags,
        {"allow":[{"domain":rs_event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
  }
  rule editOrAddForwarding {
    select when edu_byu_forwarding forwarding_requested
      name re#(.+)#
      url re#(.*)#
      setting(name,url)
    pre {
      pre_existing = wrangler:children().filter(function(c){
        c{"name"}==name}).head()
      trimmed_url = url.replace(re#^\s\s*#,"").replace(re#\s\s*$#,"")
    }
    if pre_existing then
      event:send({"eci":pre_existing{"eci"},"domain":"edu_byu_forwardee",
        "type":"newURL","attrs":{"url":trimmed_url}
      })
    fired {
      raise edu_byu_forwarding event "new_forward_url" attributes event:attrs
    } else {
      raise wrangler event "new_child_request" attributes
        event:attrs
          .delete("url")
          .put({"name":name,"backgroundColor":"#FD8328","fwd_url":trimmed_url})
    }
  }
  rule prepareForwardingPico {
    select when wrangler child_initialized
    pre {
      repo = meta:host+"/c/clfism73w05pgy44987t3exf9/query/code-repo/code.txt?rid="
      eci = event:attrs{"eci"}
    }
    every {
      event:send({"eci":eci,"domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"url":repo+"html"}
      })
      event:send({"eci":eci,"domain":"wrangler","type":"install_ruleset_request",
        "attrs":{"url":repo+"edu.byu.forwardee"}
      })
      event:send({"eci":eci,"domain":"edu_byu_forwardee","type":"newURL",
        "attrs":{"url":event:attrs{"fwd_url"}}
      })
    }
  }
  rule stopForwarding {
    select when edu_byu_forwarding forwarding_deletion_requested
      name re#(.+)#
      setting(name)
    pre {
      pre_existing = wrangler:children().filter(function(c){
        c{"name"}==name}).head()
    }
    if pre_existing then noop()
    fired {
      raise wrangler event "child_deletion_request"
        attributes event:attrs.put({"eci":pre_existing{"eci"}})
    }
  }
  rule redirectBack {
    select when edu_byu_forwarding new_forward_url
             or wrangler new_child_created
             or wrangler child_deleted
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
}
