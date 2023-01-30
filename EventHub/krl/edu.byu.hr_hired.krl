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
what = limit.klog("limit")
answer =
      sdk:events(limit,ack.decode())
.klog("answer")
which = answer.length().klog("how many")
answer
    }
  }
  rule handleSomeEvents {
    select when edu_byu_hr_hired events_in_queue
      n re#^(\d+)$# setting(n)
    foreach eh_events(n,false){["events","event"]} setting(event)
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
