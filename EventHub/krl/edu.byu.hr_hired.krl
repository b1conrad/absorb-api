ruleset edu.byu.hr_hired {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module io.picolabs.subscription alias rel
    use module edu.byu.sdk alias sdk
    shares eh_subscriptions, eh_events
  }
  global {
    eh_subscriptions = function(){
      sdk:subscriptions()
    }
    eh_events = function(limit,ack){
      answer = sdk:events(limit,ack.decode()){["events","event"]}
.klog("answer")
      answer.typeof() == "Map" => [answer] |
      answer.typeof() == "Array" => answer |
      null
    }
  }
  rule handleSomeEvents {
    select when edu_byu_hr_hired events_in_queue
    foreach eh_events(event:attr("n")||1,false) setting(event)
    pre {
      absorb = rel:established().head()
      header = event{"event_header"}
      domain = header{"domain"}
      entity = header{"entity"}
      event_type = header{"event_type"}
      dept_id = event{["filters","filter","filter_value"]}
.klog("dept_id")
      eci = absorb{"Tx"}
.klog("eci")
      dept = wrangler:picoQuery(eci,"edu.byu.absorb-api-test ","getDepartments",{"id":dept_id})
.klog("dept")
    }
  }
}
