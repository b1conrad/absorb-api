ruleset edu.byu.hr_hired {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias rel
    use module edu.byu.sdk alias sdk
    shares eh_subscriptions, eh_events, index, export, person
  }
  global {
    rs_event_domain = "edu_byu_hr_hired"
    eh_subscriptions = function(){
      sdk:subscriptions()
    }
    eh_events = function(limit,ack){
      answer = sdk:events(limit,ack.decode()){["events","event"]}
      ans_type = answer.typeof()
      ans_type == "Map" => [answer] |
      ans_type == "Array" => answer |
      null
    }
    makeMT = function(ts){
      MST = time:add(ts,{"hours": -7});
      MDT = time:add(ts,{"hours": -6});
      MDT > "2022-11-06T02" => MST |
      MST > "2022-03-13T02" => MDT |
                               MST
    }
    ts_format = function(ts){
      parts = ts.split(re#[T.]#)
      parts.filter(function(v,i){i<2}).join(" ")
    }
    index = function(){
      last = ent:hr_events.keys().length()
      del_base = <<#{meta:host}/sky/event/#{meta:eci}/none/#{rs_event_domain}/ack?id=>>
      person_url = "person.html?id="
      html:header("Hired events")
      + <<<h1>Hired events</h1>
<table>
<tr>
<th>№</th>
<th>event_id</th>
<th>event_dt</th>
<th>dept_id</th>
<th>byu_id</th>
<th>net_id</th>
<th>eff_dt</th>
</tr>
#{ent:hr_events.values().reverse().map(function(e,i){
  h = e{"event_header"}
  b = e{"event_body"}
  id = h{"event_id"}
  pid = b{"byu_id"}
<<<tr>
<td>#{i+1}</td>
<td title="#{id}"><a><a href="#{del_base+id}">del #{i+1}-#{last}</a></td>
<td>#{h{"event_dt"}.makeMT().ts_format()}</td>
<td>#{e{["filters","filter","filter_value"]}}</td>
<td><a href="#{person_url+pid}" target="_blank">#{pid}</a></td>
<td>#{b{"net_id"}}</td>
<td>#{b{"effective_date"}}</td>
</tr>
>>}).values().join("")}</table>
<a href="export.txt" target="_blank">export</a>
>>
      + html:footer()
    }
    person = function(id){
      response = sdk:persons(id)
      s_code = response{"status_code"}
      content = s_code == 200 => response{"content"} | s_code
      basic = content.decode(){"basic"}
      html:header("Person "+id)
      + <<<h1>Person #{id}</h1>
<pre>#{content}</pre>
<table>
<tr><th>id</th><td>&nbxp;</td></tr>
<tr><th>username</th><td>#{basic{["net_id","value"]}}</td></tr>
<tr><th>departmentId</th><td>TBD</td></tr>
<tr><th>firstName</th><td>#{basic{["preferred_first_name","value"]}}</td></tr>
<tr><th>lastName</th><td>#{basic{["preferred_surname","value"]}}</td></tr>
<tr><th>gender</th><td>#{basic{["sex","value"]}}</td></tr>
<tr><th>activeStatus</th><td>0</td></tr>
<tr><th>isLearner</th><td>true</td></tr>
<tr><th>isInstructor</th><td>false</td></tr>
<tr><th>isAdmin</th><td>false</td></tr>
<tr><th>hasUsername</th><td>true</td></tr>
</table>
>>
      + html:footer()
    }
    export = function(){
      th = "event_id,event_dt,dept_id,byu_id,net_id,eff_dt"
      one_line = function(e,i){
        h = e{"event_header"}
        b = e{"event_body"}
        id = h{"event_id"}
        <<#{id},#{h{"event_dt"}.makeMT().ts_format()},#{e{["filters","filter","filter_value"]}},#{b{"byu_id"}},#{b{"net_id"}},#{b{"effective_date"}}>>
      }
      lines = ent:hr_events.values().map(one_line).join(chr(10))
      th + chr(10) + lines
    }
  }
  rule fetchSomeEvents {
    select when edu_byu_hr_hired events_in_queue
    foreach eh_events(event:attr("n")||1,false) setting(event)
    pre {
//      absorb = rel:established().head()
//      eci = absorb{"Tx"}
//      dept_id = event{["filters","filter","filter_value"]}
//      dept = wrangler:picoQuery(eci,"edu.byu.absorb-api-test ","getDepartments",{"id":dept_id})
//      body = event{"event_body"}
//      byu_id = body{"byu_id"}
//      net_id = body{"net_id"}
//      eff_dt = body{"effective_date"}
      event_id = event{["event_header","event_id"]}
    }
    fired {
      ent:hr_events{event_id} := event
      raise edu_byu_hr_hired event "hired_event_fetched" attributes {"event":event}
    }
  }
  rule reactToWebhook {
    select when HR_Personal_Action Hired
    pre {
      event = event:attr("event")
      event_id = event{["event_header","event_id"]}
    }
    fired {
      ent:hr_events{event_id} := event
      raise edu_byu_hr_hired event "hired_event_received" attributes event:attrs
    }
  }
  rule acknowledgeEvents {
    select when edu_byu_hr_hired ack
    sdk:acknowledge(event:attr("id")) setting(response)
    fired { // todo prune ent:hr_events
      raise edu_byu_hr_hired event "events_acknowledged" attributes response
    }
  }
  rule redirectBack {
    select when edu_byu_hr_hired ack
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
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
}
