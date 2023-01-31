ruleset edu.byu.hr_hired {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias rel
    use module edu.byu.sdk alias sdk
    shares eh_subscriptions, eh_events, index
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
      html:header("Hired events")
      + <<<h1>Hired events</h1>
<table>
<tr>
<th>№</th>
<th>event_id</th>
<th>event_dt</th>
<th>dept</th>
<th>byu_id</th>
<th>net_id</th>
<th>eff_dt</th>
</tr>
#{ent:hr_events.values().reverse().map(function(e,i){
  h = e{"event_header"}
  b = e{"event_body"}
<<<tr>
<td>#{i+1}</td>
<td><span title="#{h{"event_id"}}">del</span></td>
<td>#{h{"event_dt"}.makeMT().ts_format()}</td>
<td>#{e{["filters","filter","filter_value"]}}</td>
<td>#{b{"byu_id"}}</td>
<td>#{b{"net_id"}}</td>
<td>#{b{"effective_date"}}</td>
</tr>
>>}).values().join("")}</table>
>>
      + html:footer()
    }
  }
  rule handleSomeEvents {
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
}
