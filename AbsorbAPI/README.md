# Absorb API

Documented here: [RESTful API v1 Help](https://myabsorb.com/api/rest/v1/Help)

And, we've learned that we'll need to update to v1.5, documented here: [Absorb REST API v1.5](https://byu.myabsorb.com/v1_5-doc/)

## Installing rulesets in Absorb picos

Notice that precisely the same rulesets are to be installed in:
1. the Absorb sandbox pico
2. the Absorb production pico

The only difference is in the configuration at the time the ruleset is installed.
See more detail in the `krl` folder.

New development while in production can proceed in sandbox
by leaving the production pico as it is but putting newer versions of
the rulesets into the sandbox pico.
