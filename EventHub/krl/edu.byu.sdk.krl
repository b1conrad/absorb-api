ruleset edu.byu.sdk {
  meta {
    provides tokenValid, subscriptions, events, acknowledge, persons
    shares latestResponse, theToken, tokenValid, persons
  }
  global {
    latestResponse = function(){
      ent:latestResponse
    }
    theToken = function(){
      ent:token{"access_token"}
    }
    ClientID = meta:rulesetConfig{"ClientID"}
    ClientSecret = meta:rulesetConfig{"ClientSecret"}
    api_url = "https://api.byu.edu/"
    tokenValid = function(){
      tokenTime = ent:valid
      ent:token{"access_token"}
.klog("theToken")
      && tokenTime
.klog("timestamp")
      && (time:add(tokenTime,{"hours":2}) > time:now())
.klog("not yet expired")
    }
    hdrs = function(){
      {
        "Content-Type":"application/json",
        "Authorization":"Bearer "+ent:token{"access_token"}
      }
    }
    subscriptions = function(){
      url = api_url + "domains/eventhub/v2/subscriptions"
      response = http:get(url,headers=hdrs())
      status = response{"status_code"}
      status == 200 => response{"content"}.decode() | status
    }
    events = function(limit,ack){
      url = api_url + "domains/eventhub/v2/events"
      args = { "count":limit, "acknowledge":ack.encode() }
      response = http:get(url,headers=hdrs(),qs=args)
      status = response{"status_code"}
      status == 200 => response{"content"}.decode() | status
    }
    acknowledge = defaction(event_id){
      url = api_url + "domains/eventhub/v2/events/" + event_id
      http:put(url,headers=hdrs()) setting(response)
      return response
    }
    persons = function(id){
      url = api_url + "byuapi/persons/" + id
      http:get(url,headers=hdrs()
.klog("hdrs")
)
    }
  }
  rule generateAuthenticationToken {
    select when edu_byu_sdk tokenNeeded
    pre {
      creds = {
        "username":ClientID,
        "password":ClientSecret,
      }
      data = {"grant_type":"client_credentials"}
    }
    http:post(api_url+"token",auth=creds,form=data) setting(response)
    fired {
      ent:latestResponse := response
      ent:token := response{"status_code"}==200 => response{"content"}.decode()
                                                 | null
      ent:valid := time:now()
    }
  }
}
