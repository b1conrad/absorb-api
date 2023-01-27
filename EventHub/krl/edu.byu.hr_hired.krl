ruleset edu.byu.hr_hired {
  meta {
    use module edu.byu.sdk alias sdk
    shares subscriptions
  }
  global {
    subscriptions = function(){
      sdk:subscriptions()
    }
  }
}
