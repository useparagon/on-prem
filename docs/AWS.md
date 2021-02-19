## This document is a work in progress.

## Troubleshooting

### EC2 deployment hangs

This can happen when an `apt-get` install is left pending. SSH into your EC2 instance and try running the following commands:

```
sudo apt-get update && sudo apt-get upgrade
sudo apt-get -f install
sudo apt-get autoremove
sudo dpkg --configure -a
```

If those don't work, run this command:

```
ps aux | grep -i apt
```

Find the process ids of any results and run:

```
sudo kill -9 <PID>
```

**Helpful Links**

https://itsfoss.com/could-not-get-lock-error/
