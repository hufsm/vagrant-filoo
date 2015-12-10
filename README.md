# vagrant-filoo
Vagrant filoo provisioner

This is a Vagrant 1.7x plugin that adds an  provider for filoo hosting to Vagrant, allowing Vagrant to control and provision machines within the filoo public and private cloud.


![htps://www.filoo.de/vserver.html](/doc/img_res/filoo_logo.png?raw=true )

htps://www.filoo.de/vserver.html

NOTE: This plugin requires Vagrant 1.7x

#TODO
- set servername 4.1.16 vserver/setcustomname
- support network features

```
config.vm.network "private_network", ip: "192.168.0.17"
config.vm.network "public_network", ip: "192.168.0.17"
```

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After installing, `vagrant up` and specify the `filoo` provider. An example is shown below.

```
$ vagrant plugin install vagrant-filoo
...
$ vagrant up --provider=filoo
...
```

Of course prior to doing this, you'll need to obtain an Filoo-compatible box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get started is to actually use a dummy Filoo box and specify all the details manually within a `config.vm.provider` block. So first, add the dummy box using any name you want:

```
$ vagrant box add dummy <url to dummy box>
...
```

And then make a Vagrantfile that looks like the following, filling in your information where necessary.

It is good practice to access the filoo api key via system environment variable. To use environment variable FILOO_API_KEY add following line in the Vagrantfile
```
filoo.filoo_api_key = ENV['FILOO_API_KEY']
```

as seen in the commented line of config beneath.

```
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :filoo do |filoo, override|
   filoo.filoo_api_key = "your filoo api access key" 
   # or to use environment variable uncomment this
   #filoo.filoo_api_key = ENV['FILOO_API_KEY']
    
   filoo.filoo_api_entry_point = "https://api.filoo.de/api/v1"
   filoo.cd_image_name = "Debian 7.7 - 64bit"
   filoo.type =  "dynamic"
   filoo.cpu = 1
   filoo.ram = 128
   filoo.hdd = 10
   filoo.additional_nic = true # defaults to false
  end
end
```

And then run 'vagrant up --provider=filoo'.

This will start an Debian 6.0 - 64bit instance in the Filoo infrastructure

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.


## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `filoo` boxes. You can view an example box in
the [example_box/ directory](<path to repository>/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `filoo_api_key` - The api key for accessing Filoo
* `cd_image_name` - The Filoo omage name to boot, such as ""Debian 6.0 - 64bit"
* `filoo_api_entry_point` - The base url to the api "https://api.filoo.de/api/v1"

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :filoo do |filoo|
    filoo.filoo_api_key = "foo"
    filoo.filoo_api_entry_point = "bar"
    filoo.cd_image_name = "foo-bar"
  end
end
```

## Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-filoo`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the filoo machine.

## Synced Folders

Shared folders are not supported at the current state.

Linux and Windows clients optionally can use sshfs to mount a folder on the network or to connect a network drive. While the Linux implementation via fuse is quite stable the windows variant is not. We have successfully  tested under Windows 7. Under Windows the re-connect after a network cut-off sometimes fails.

General Information: https://de.wikipedia.org/wiki/SSHFS
Windows build: https://code.google.com/p/win-sshfs/

See [Vagrant Synced folders: rsync](https://docs.vagrantup.com/v2/synced-folders/rsync.html)


## Other Examples



## Development

To work on the `vagrant-filoo` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
and add the following line to your `Vagrantfile`
```ruby
Vagrant.require_plugin "vagrant_filoo"
```
Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=filoo
```
