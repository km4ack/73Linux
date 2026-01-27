#73Linux
## Description

73 Linux is the next evolution of Build a Pi. Not only does 73 Linux support Raspberry Pi
but it also supports x86_64 Debian based systems. Now you can load up a laptop running
Ubuntu or Mint with the same ease as previously on the Pi. To keep with the Build a Pi
traditions, you have **FULL** control over the build unlike pre-built images. It allows you to 
choose the applications you  want to install and skip the ones you don’t need. This keeps 
your system as lean and mean as possible. 

Another great feature is the ability to "side load" new apps. Anyone can write a bapp file
and drop it in the community directory and the 73 Linux menu system will automatically
load it right along with the core apps.

Just one small example of a custom bapp file would be if your organization uses a custom
Winlink form or custom FLMSG form. One savvy Linux user from your group could write a 
custom bapp file to help others in the organization be certain the forms got installed
to the correct directory.

End users still have full control over custom files and can choose to show or ignore
bapp files not included in the official 73 Linux package.

# Compatibility

So far 73 Linux has been tested on the Pi 4 running Pi OS 32bit and the Evolve Maestro
laptop. 

You can run 73 Linux right on top of your old Build a Pi install. ~~73 Linux will remove 
any old installs of BAP during the initial run.~~ Coming soon.

# Install

**Note:** VARA may not install on the first run. If it doesn't, run 73 Linux again and just choose VARA
on the second run. 

Install is still super easy. Just run the following command:

     git clone https://github.com/km4ack/73Linux.git $HOME/73Linux && bash $HOME/73Linux/73.sh

If the above command fails, you may be missing git. If so, run

     sudo apt install git

and then run the git clone command again.

# Issue reporting  and feature Requests

https://github.com/km4ack/73Linux/issues

# More documentation coming soon!

# Credits

A big thank you to Kelly Keaton for his huge contribution to the new menu system, the Patrons for their time testing early versions,
and everyone who has reported bugs over the years. Each of you has helped make this project what it is today. Other code contributors include:

jangliss
Jehreg
Rescue9
hsmalley
chrisBosse
kuperman
NullVibes
