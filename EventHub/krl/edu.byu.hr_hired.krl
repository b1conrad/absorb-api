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
      ans_type = answer.typeof()
      ans_type == "Map" => [answer] |
      ans_type == "Array" => answer |
      null
    }
  }
  rule handleSomeEvents {
    select when edu_byu_hr_hired events_in_queue
    foreach eh_events(event:attr("n")||1,false) setting(event)
    pre {
      absorb = rel:established().head()
      eci = absorb{"Tx"}
      dept_id = event{["filters","filter","filter_value"]}
      dept = wrangler:picoQuery(eci,"edu.byu.absorb-api-test ","getDepartments",{"id":dept_id})
.klog("dept")
      body = event{"event_body"}
      byu_id = body{"byu_id"}
.klog("byu_id")
      net_id = body{"net_id"}
.klog("net_id")
      eff_dt = body{"effective_date"}
.klog("eff_dt")
    }
  }
}
