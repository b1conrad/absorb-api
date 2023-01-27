# Event Hub

The steps for subscribing to events published on the Event Hub are sketched out 
in the answer to ["How does my application subscribe to events on Event Hub? #52"](https://github.com/byu-oit/appeng-questions/discussions/52).

## Sandbox Event Hub

Assuming we can arrange for the events of interest to be sent through the sandbox event hub, 
we followed these instructions:

1. create an OAuth client that represents the application

This is done at the BYU Tyk Credential Manager, https://tcm.byu.edu/
(a Mendix application). Once logged in, we clicked the "Create a New Client" button
and were presented with a dialog box. (see NewOAuthClient.png in this same folder)

The client ID is pre-populated (it is an opaque identifier (so no dependence on the App Name)).
We provided the App Name "bc-absorb-real-time-from-hr" (it just has to be something that you'll recognize later).

When ready, we clicked the "Generate Secret" button and copied the secret and put it in a couple of safe places
(it just has to be someplace that you'll be able to find later (and that others are unlikely to look)).

1½. Have a non-person identity set up for the app

This is done by Dan McNeece and he wanted to know:
- the sandbox client id (from step 1)
- what the identity should be called; we went with "IICS Absorb udpater" (note: not the same as the App Name from step 1)

Then he gave us the identifier (which I believe is not secret, but in case, let's just say it is a 9 digit number).

2. obtain an OAuth token for this client

For sandbox, this is this `curl` command:
```
curl --location --request POST 'https://api-sandbox.byu.edu/token' \
--header 'Authorization: Basic YTpi' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode 'grant_type=client_credentials'
```

Where YTpi is the base64 encoding of the client id, a colon, and the client secret.
Say the client id were "a" and the client secret "b" then since `a:b` base64 encodes as `YTpi` that's what's shown above.
With real values, it'll be a lot longer, but that's where it goes.

The result returned by `curl` will look like this:
```
{"access_token":"V9w4qqROdxredactedtlyo6Xeb4","expires_in":3599,"scope":"","token_type":"bearer"}
```
The actual token is a lot longer than that. 
Note that there is a notion of expiration, perhaps that means one hour?
Note that it is a "bearer" token.

3. paste that OAuth token into the field on https://eventhub-console-dev.byu.edu/

3½. write some code that will process an event and get a URL to call it with (i.e. a webhook)

4. configure a webhook that will be invoked by EventHub when events are delivered.

5. subscribe to any events you care about.

In our case, that is [this one event](https://developer-old.byu.edu/event/hired-hrpersonalaction) (described hierarchically)
- byu.edu
    - HR_Personal_Actions
        - Hired
  
