# uucodebase-script
A script to set ssh key pair for uuCodebase. It creates private and public key for you, setup ssh config file to use that keys uuCodebase and uploads public key to the uuCodebase so you do not have to crawl through the documentation nor you have to create extension less file in windows.

It is a bash script that runs just fine in git bash which is automatically installed with git on windows, other (used) systems can run bash commands out of box.

## Usage

Download raw version of `codebase.sh` file, put it into your home directory (`/home/<user>` on unix systems, `C:/Users/<user>` on windows) and navigate to the file in bash. If you are on unix systems, you have to set execution rights for the file by `chmod +x ./codebase.sh`, on windows, you are good to go. 

Basic usage is just to call the script and pass in your UID
```
./codebase.sh <uid>
```
#### Example
```
./codebase.sh 6-138-1
```
This will create private key names `6-138-1` in your home `.ssh` folder, for unix systems it set proper rights (unix requires private keys to be readable only for owners). There will also be a public key in file `6-138-1.pub`. Then it adds some usage rules into your `.ssh/config` file so the key is used only with uuCodebase while you are free to use any other key pair with services you use. If you already have a `config` file, it will just append the rules. If you happen to already have a rule for uuCodebase in your `config`, it will try to replace just the `IdentityFile` parameter.

When the key is created, you will be asked to provide _Access Code 1_ and _Access Code 2_. When provided, the script will automatically upload your public key into uuCodebase service. The access codes are hidden during writing so don't be alarmed when you can't see any characters poping up.

When you run the script multiple times, it will detect already existing key with the same name (same UID) and offer you choice to regenerate it (overwrite it). Default value is to preserve the existing key, you have to manually opt in to overwrite it.

## Parameters

There are also some parameters you can use while executing the script

* `-o, --overwrite` - overwrites existing keys with new ones without asking
* `-c, --create-only` - only creates key pair and sets config. It skips uploading to uuCodebase
* `-p, --path PATH` - specify path where to create key pair. Default values is `~/.ssh`
* `-h, --help` - show some help text
