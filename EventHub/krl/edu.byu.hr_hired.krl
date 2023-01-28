ruleset edu.byu.hr_hired {
  meta {
    use module io.picolabs.subscription alias rel
    use module edu.byu.sdk alias sdk
    shares eh_subscriptions, eh_events
  }
  global {
    eh_subscriptions = function(){
      sdk:subscriptions()
    }
    eh_events = function(limit,ack){
      sdk:events(limit,ack.decode())
    }
  }
  rule handleSomeEvents {
    select when allowedu_byu_hr_hired events_in_queue
    foreach eh_events(2,false){["events","event"]} setting(event)
    pre {
      header = event{"event_header"}
.klog("header")
      domain = header{"domain"}
.klog("domain")
      entity = header{"entity"}
.klog("entity")
      event_type = header{"event_type"}
.klog("event_type")
      dept_id = event{["filters","filter","filter_value"]}
.klog("dept_id")
    }
  }
}
