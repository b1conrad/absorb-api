ruleset com.absorb.sdk {
  meta {
    provides Authenticate
  }
  global {
    Username = meta:rulesetConfig{"Username"}
    Password = meta:rulesetConfig{"Password"}
    PrivateKey = meta:rulesetConfig{"PrivateKey"}
    Authenticate = function(){
      BodyParameters = {
        "Username":Username,
        "Password":Password,
        "PrivateKey":PrivateKey
      }
      api_url = "https://byu.sandbox.myabsorb.com/api/Rest/v1/Authenticate"
      http:post(api_url,json=BodyParameters)
    }
  }
}
