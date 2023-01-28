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
      sdk:events()
    }
  }
}
