ruleset edu.byu.hr_hired {
  meta {
    use module html
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias rel
    use module edu.byu.sdk alias sdk
    shares eh_subscriptions, eh_events, index, export, person, forward, import
, getNewUserAccount
, getExistingUserAccount
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
      prune_it = <<#{meta:host}/sky/event/#{meta:eci}/none/#{rs_event_domain}/prune>>
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
<th>department</th>
</tr>
#{ent:hr_events.values().reverse().map(function(e,i){
  h = e{"event_header"}
  b = e{"event_body"}
  id = h{"event_id"}
  pid = b{"byu_id"}
  url = "person.html?event_id="+id
  dept_id = e{["filters","filter","filter_value"]}
  a_id = ent:doi >< dept_id => ent:doi{dept_id}.encode() | ""
<<<tr>
<td>#{last-i}</td>
<td title="#{id}">#{id.substr(0,7)}…</td>
<td>#{h{"event_dt"}.makeMT().ts_format()}</td>
<td>#{dept_id}</td>
<td><a href="#{url}" target="_blank">#{pid}</a></td>
<td>#{b{"net_id"}}</td>
<td>#{b{"effective_date"}}</td>
<td>#{a_id}</td>
</tr>
>>}).values().join("")}</table>
<a href="export.txt" target="_blank">export</a>
<form action="#{prune_it}">
Prune keeping
<input type="number" name="keeping" min="0" max="#{last}" required>
latest events.<br/>
<button type="submit">prune</button>
</form>
>>
      + html:footer()
    }
    getNewUserAccount = function(event_id){
      e = ent:hr_events{event_id}
      dept_id = e{["filters","filter","filter_value"]}
      eci = rel:established().head().get("Tx")
      dept = ent:doi >< dept_id => ent:doi{dept_id}
                                 | wrangler:picoQuery(
                                     eci,
                                     "edu.byu.absorb-api-test",
                                     "getDepartments",
                                     {"id":dept_id}
                                   ).head()
      id = e{["event_body","byu_id"]}
      content = sdk:persons(id)
      basic = content{"basic"}
      emailKeys = [
        "byu_internal_email",
        "personal_email_address",
        "student_email_address",
      ]
      emailAddress = emailKeys.reduce(function(a,k){
          a => a | basic{[k,"value"]}
        },"")
      obj = {
        "id": "",
        "username": basic{["net_id","value"]},
        "departmentId": dept.encode() || "@" + dept_id,
        "firstName": basic{["preferred_first_name","value"]},
        "lastName": basic{["preferred_surname","value"]},
        "emailAddress": emailAddress,
        "externalId": id,
        "gender": "@" + basic{["sex","value"]},
        "activeStatus":0,
        "isLearner":true,
        "isInstructor":false,
        "isAdmin":false,
        "hasUsername":true,
      }
      obj
    }
    getExistingUserAccount = function(event_id){
      e = ent:hr_events{event_id}
      net_id = e{["event_body","net_id"]}
      eci = rel:established().head().get("Tx")
      accts = wrangler:picoQuery(eci,"edu.byu.absorb-api-test","getUsers",{"net_id":net_id})
.klog("accts")
      acct = accts.typeof()=="Array" && accts.length() => accts.head() | null
      dept = acct => wrangler:picoQuery(eci,"edu.byu.absorb-api-test","getDepartmentById",{"id":acct{"DepartmentId"}}) | null
      obj = acct => {
        "id": acct{"Id"},
        "username": acct{"Username"},
        "departmentId": dept.encode() || acct{"DepartmentId"},
        "firstName": acct{"FirstName"},
        "lastName": acct{"LastName"},
        "emailAddress": acct{"EmailAddress"},
        "externalId": acct{"ExternalId"},
        "gender": acct{"Gender"},
        "activeStatus": acct{"ActiveStatus"},
        "isLearner": acct{"IsLearner"},
        "isInstructor": acct{"IsInstructor"},
        "isAdmin": acct{"IsAdmin"},
        "hasUsername": acct{"HasUsername"},
      } | null
      obj
    }
    person = function(event_id){
      base_url = <<#{meta:host}/sky/event/#{meta:eci}/none/#{rs_event_domain}>>
      url = base_url + "/new_account"
      e = ent:hr_events{event_id}
      id = e{["event_body","byu_id"]}
      nua = getNewUserAccount(event_id)
      eua = getExistingUserAccount(event_id)
      html:header("Person "+id)
      + <<<h1>Person #{id}</h1>
<h2>New Account</h2>
<table>
#{nua.map(function(v,k){
<<<tr><th>#{k}</th><td>#{v}</td></tr>
>>
}).values().join("")}</table>
<a href="#{url+"?event_id="+event_id}">Manually create Absorb account</a>
<h2>Existing Account</h2>
<table>
#{eua => eua.map(function(v,k){
<<<tr><th>#{k}</th><td>#{v}</td></tr>
>>
}).values().join("") | "<tr><td>N/A</td></tr>"}</table>
<h2>Notes</h2>
<pre contenteditable>paste data here</pre>
<p contenteditable>write comments here</p>
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
<tr><th>name</th><th>url</th><th></th></tr>
#{ent:forward.values().map(function(v){
<<<tr><td>#{v{"name"}}</td><td>#{v{"url"}}</td><td>#{delr(v)}</td></tr>
>>}).join("")}
<tr>
<td><input onchange="#{js1("name")}" required placeholder="name"></td>
<td><input onchange="#{js1("url")}" required class="wide90" placeholder="url"></td>
<td><button onclick="#{js2()}">add</button></td>
</td></tr>
</table>
<form id="forward_form" action="#{url}">
<input id="forward_name" name="name" type="hidden">
<input id="forward_url" name="url" type="hidden">
</form>
>>
      + html:footer()
    }
    newline = (13.chr() + "?" + 10.chr()).as("RegExp")
    import = function(){
      base_url = <<#{meta:host}/sky/event/#{meta:eci}/none/#{rs_event_domain}>>
      html:header("Import")
      + <<<h1>Import</h1>
<form action="#{base_url}/import_data_available">
<textarea name="import_data"></textarea>
<button type="submit">Submit</button>
</form>
>>
      + html:footer()
    }
  }
  rule fetchSomeEvents { // not currently used
    select when edu_byu_hr_hired events_in_queue
    foreach eh_events(event:attr("n")||1,false) setting(event)
    pre {
      event_id = event{["event_header","event_id"]}
    }
    fired {
      ent:hr_events{event_id} := event
      raise edu_byu_hr_hired event "hired_event_fetched" attributes {"event":event}
    }
  }
  rule acknowledgeEvents { // not currently used
    select when edu_byu_hr_hired ack
    sdk:acknowledge(event:attr("id")) setting(response)
    fired {
      raise edu_byu_hr_hired event "events_acknowledged" attributes response
    }
  }
  rule reactToWebhook {
    select when HR_Personal_Action Hired
    pre {
      event = event:attr("event")
      event_id = event{["event_header","event_id"]}
      byu_id = event{["event_body","byu_id"]}
      valid_payload = event && event_id && byu_id
    }
    if valid_payload then noop()
    fired {
      ent:hr_events{event_id} := event
      raise edu_byu_hr_hired event "hired_event_received" attributes event:attrs
    }
  }
  rule internalFollowUp {
    select when edu_byu_hr_hired hired_event_received
    pre {
      event = event:attr("event")
      dept_id = event{["filters","filter","filter_value"]}
      of_interest = ent:doi >< dept_id
      my_eci = of_interest => wrangler:channels("event_hub,sdk-and-test")
                            | null
    }
    if of_interest then every {
      event:send({
        "eci":my_eci,
        "domain":"edu_byu_sdk",
        "type":"token_check_needed"
      })
      event:send({
        "eci":my_eci,
        "domain":"edu_byu_hr_hired",
        "type":"new_hire_of_interest",
        "attrs":event:attrs
      })
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
  rule pruneKeeping {
    select when edu_byu_hr_hired prune
    pre {
      keeping = event:attr("keeping").as("Number")
      last = ent:hr_events.length()
      valid = 0 <= keeping && keeping <= last
      remove = last - keeping
      kept_event_ids = keeping => ent:hr_events.keys().splice(0,remove)
                                | []
      number_kept = kept_event_ids.length()
.klog("number_kept")
      kept_events = ent:hr_events.filter(function(v,k){kept_event_ids >< k})
    }
    if valid && number_kept == keeping then noop()
    fired {
      ent:hr_events := kept_events
    }
  }
  rule addForwarding {
    select when edu_byu_hr_hired forwarding_requested
      name re#(.+)#
      url re#(.+)#
      setting(name,url)
    pre {
      entry = {"name":name,"url":url}
    }
    fired {
      ent:forward := ent:forward.defaultsTo({}).put(name,entry)
      raise edu_byu_hr_hired event "new_forward" attributes event:attrs
    }
  }
  rule stopForwarding {
    select when edu_byu_hr_hired forwarding_deletion_requested
      name re#(.+)#
      setting(name)
    if ent:forward.keys() >< name then noop()
    fired {
      clear ent:forward{name}
      raise edu_byu_hr_hired event "new_forward" attributes event:attrs
    }
  }
  rule manuallyCreateNewAbsorbAccount {
    select when edu_byu_hr_hired new_account
    pre {
      event_id = event:attrs{"event_id"}
      event = ent:hr_events{event_id}
      my_eci = wrangler:channels("event_hub,sdk-and-test")
    }
    if event then every {
      event:send({
        "eci":my_eci,
        "domain":"edu_byu_sdk",
        "type":"token_check_needed"
      })
      event:send({
        "eci":my_eci,
        "domain":"edu_byu_hr_hired",
        "type":"new_hire_of_interest",
        "attrs":{"event":event}
      })
    }
  }
  rule redirectBack {
    select when edu_byu_hr_hired ack
             or edu_byu_hr_hired prune
             or edu_byu_hr_hired new_forward
             or edu_byu_hr_hired new_account
    pre {
      referrer = event:attr("_headers").get("referer") // sic
    }
    if referrer then send_directive("_redirect",{"url":referrer})
  }
  rule importDepartmentsOfInterest {
    select when edu_byu_hr_hired import_data_available
    foreach event:attrs{"import_data"}.split(newline) setting(line)
    pre {
      fields = line.split(chr(9))
      entry = {"code":fields.head(),"name":fields[1]}
    }
    if fields.head().match(re#\d{4}#) then noop()
    fired {
      raise edu_byu_hr_hired event "new_doi" attributes entry
    }
  }
  rule importOneDepartment {
    select when edu_byu_hr_hired new_doi
    pre {
      code = event:attrs{"code"}
      name = event:attrs{"name"}
      eci = rel:established().head().get("Tx")
      dept = wrangler:picoQuery(eci,"edu.byu.absorb-api-test","getDepartments",{"id":code}).head()
      entry = {"code":code,"name":name,"a_id":dept{"Id"}}
    }
    fired {
      ent:doi := ent:doi.defaultsTo({}).put(code,entry)
    }
  }
  rule createNewAbsorbAccount {
    select when edu_byu_hr_hired new_hire_of_interest
    pre {
      event = event:attr("event")
      event_id = event{["event_header","event_id"]}
      nua = getNewUserAccount(event_id)
      eci = rel:established().head().get("Tx")
    }
    if eci && nua{"externalId"} && nua{"username"} then
      event:send({
        "eci":eci,
        "domain":"absorb_api_test",
        "type":"account_requested",
        "attrs":nua
      })
    fired {
      raise edu_byu_hr_hired event "account_requested" attributes event:attrs
    }
  }
}
