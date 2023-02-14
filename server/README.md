# server setup

This is a proof of concept.

Development and a brief beta test in production will take place on the same machine.

## NodeJS

We elected to use NodeJS and picos, because of familiarity.

Ultimately, production will be an IICS integration, replacing this proof of concept.

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
$ PICO_ENGINE_BASE_URL=http://ubu-test-bruce.byu.edu:3000 nohup pico-engine &
```

## Picos

The proof of concept involved the creation of three picos:
- IICS Absorb updater to listen to Event Hub, present a dashboard, and ask for new Absorb accounts
- Absorb sandbox to interact with byu.sandbox.myabsorb.com and create new accounts and update existing accounts
- Absorb production to interact with byu.myabsorb.com and create/update accounts in production

<img width="732" alt="ProofOfConceptPicos" src="https://user-images.githubusercontent.com/19273926/218779155-f2a888f0-9824-4ca2-97cc-6fe619fe19d9.png">
