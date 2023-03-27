# server setup

This is a proof of concept.

Development and a brief beta test in production will take place on the same machine.

## NodeJS

We elected to use NodeJS and picos, because of familiarity.

Ultimately, production will be an full stack integration, replacing this proof of concept.

## Ubuntu

We selected Ubuntu because of familiarity.

Our Platform team set up a machine at ubu-test-bruce.byu.edu for this purpose,
and installed `node`, `npm`, and `pico-engine`.

Versions are
```
$ node --version
v12.22.9
$ npm --version
8.5.1
$ npm ls -g pico-engine
/usr/local/lib
└── pico-engine@1.2.0
```

The pico engine is started with this command (after `ssh`ing into the server):
```
$ sudo /usr/bin/systemctl start pico-engine
```

## Picos

The proof of concept involved the creation of three picos:
- IICS Absorb updater to listen to Event Hub, present a dashboard, and ask for new Absorb accounts
- Absorb sandbox to interact with byu.sandbox.myabsorb.com and create new accounts and update existing accounts
- Absorb production to interact with byu.myabsorb.com and create/update accounts in production

<img width="732" alt="ProofOfConceptPicos" src="https://user-images.githubusercontent.com/19273926/218779155-f2a888f0-9824-4ca2-97cc-6fe619fe19d9.png">

### Manual setup of the uptake pico

1. Create pico named "IICS Absorb updater"
1. In that pico create a channel tagged "iics-absorb-updater,intake" and use its identifer as the ECI in a URL
1. Register that URL, `http://ubu-test-bruce.byu.edu:3000/c/ECI/event/HR_Personal_Action/Hired`, as the web hook with Event Hub
1. Watch the pico's Logging tab to see how the data is received when this event is seen
1. Install ruleset `edu.byu.sdk` in this pico, with config like `{"ClientID":"GUID","ClientSecret":"KEY"}`
1. Create a channel tagged "event_hub,sdk-and-test" allowing events `edu_byu_sdk : *` and `edu_byu_hr_hired : *` and queries `edu.byu.sdk / *` and `edu.byu.hr_hired / *`
1. Using this channel in the Testing tab, verify that a token can be generated
1. Install ruleset `edu.byu.hr_hired` in this pico, with empty config `{}`

### Manual setup of the outflow pico

1. Create a pico named "Absorb sandbox" (a sibling of the first pico created)
1. Install ruleset `com.absorb.sdk` in this pico, with config like `{"SubDomain":"byu.sandbox","Username":"NETID","Password":"PWD","PrivateKey":"GUID"}`
1. Create a channel tagged "absorb-api,sdk-and-test" allowing events `com_absorb_sdk : *` and `absorb_api_test : *` and queries `com.absorb.sdk / *` and `edu.byu.absorb-api-test / *`
1. Using this channel in the Testing tab, verify that a token can be generated
1. Install ruleset `edu.byu.absorb-api-test` in this pico, with empty config `{}`

### Manual setup of relationship between these picos

The IICS Absorb updater pico expects a relationship with the Absorb sandbox pico.

1. In the Channels tab of the IICS Absorb updater, copy the id of the channel tagged "wellknown_rx,tx_rx"
1. In the Subscriptions tab of the Absorb sandbox pico, paste this into the "wellKnown_Tx" box, along with an "Rx_role" of "outflow", a "Tx_role" of "uptake", the name "uptake-outflow", and "channel_type" of "subscription" and click the "Add" button
1. Back in the Subscriptions tab of the IICS Absorb updater, check the box of the Inbound Subscription and accept it

### Manual setup for production

Repeat the last two sets of steps for a new pico named "Absorb production" using a non-person Net-ID for the "Username", "byu" for the "SubDomain", and the correct GUID for the "PrivateKey"

## Going into production

Delete the relationship between IICS Absorb updater and Absorb sandbox using the Subscriptions tab in either pico.
