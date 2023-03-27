# Using SYSTEMD

This will restart the pico engine automatically when the server is rebooted.

Here is the INI file to be placed in `/etc/systemd/system/pico-engine.service`:

```
[Unit]
Description=pico-engine
After=remote-fs.target

[Service]
User=adm.b1conrad
Environment="PICO_ENGINE_BASE_URL=http://ubu-test-bruce.byu.edu:3000"
ExecStart=/usr/local/bin/pico-engine
Restart=always


```

