ruleset edu.byu.absorb-api-test {
  meta {
    use module io.picolabs.wrangler alias wrangler
    use module com.absorb.sdk alias absorb
    shares getAuthenticationToken, getCategories
  }
  global {
    event_domain = "absorb_api_test"
    getAuthenticationToken = function(){
      absorb:getToken()
    }
    getCategories = function(){
      absorb:tokenValid() => absorb:categories()
                           | "token needed"
    }
  }
  rule initialize {
    select when wrangler ruleset_installed where event:attr("rids") >< meta:rid
    every {
      wrangler:createChannel(
        ["absorb-api-test"],
        {"allow":[{"domain":event_domain,"name":"*"}],"deny":[]},
        {"allow":[{"rid":meta:rid,"name":"*"}],"deny":[]}
      )
    }
    fired {
      raise absorb_api_test event "factory_reset"
    }
  }
  rule keepChannelsClean {
    select when absorb_api_test factory_reset
    foreach wrangler:channels(["absorb-api-test"]).reverse().tail() setting(chan)
    wrangler:deleteChannel(chan.get("id"))
  }
  rule generateAuthenticationToken {
    select when absorb_api_test factory_reset
             or absorb_api_test token_needed
    fired {
      raise com_absorb_sdk event "tokenNeeded"
    }
  }
}
