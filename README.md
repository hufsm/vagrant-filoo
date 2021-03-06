# vagrant-filoo
This is a Vagrant 1.7x plugin. It adds an vagrant provider for filoo hosting to Vagrant, allowing Vagrant to control and provision machines within the filoo public and private cloud.

![htps://www.filoo.de/vserver.html](/doc/img_res/filoo_logo.png?raw=true ) 

htps://www.filoo.de/vserver.html

**NOTE:** This plugin requires Vagrant 1.7x

## Changelog

* You find the most current version on the [Release](https://github.com/hufsm/vagrant-filoo/releases/latest) page along with a changelog
* Grab the [gem](https://rubygems.org/gems/vagrant_filoo)

## TODO

- set servername 4.1.16 vserver/setcustomname (API does not support it yet)
- set initial root passwort of a machine for modification and delete actions to improve machine security

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After installing, `vagrant up`, specify the `filoo` provider and import a dummy vagrant box:

```
$ vagrant plugin install vagrant_filoo
$ vagrant box add filoo https://github.com/hufsm/vagrant-filoo/raw/master/filoo.box
$ vagrant up --provider=filoo
```

After installing the plugin (instructions above), the quickest way to get started is to specify all the details manually within a `config.vm.provider` block of your Vagrantfile. You can either adapt the example to your needs or start from scratch by initiating a Vagrantfile

```
$ vagrant init --provider=filoo
```

It is good practice to access the filoo api key via system environment variable. To use environment variable FILOO_API_KEY add following line in the Vagrantfile or set the varaible in your OS: FILOO_API_KEY=<your api key>

```
Vagrant.configure("2") do |config|
  config.vm.box = "filoo"

  config.vm.provider :filoo do |filoo|
    # to carry the API Key in the Vagrantfile  comment this out:
    #filoo.filoo_api_key = "Your Api key"
    filoo.filoo_api_key = ENV['FILOO_API_KEY']
    filoo.filoo_api_entry_point = "https://api.filoo.de/api/v1"
    filoo.cd_image_name = "Debian 8.0 - 64bit"
    filoo.type =  "dynamic"
    filoo.cpu = 4
    filoo.ram = 8192
    filoo.hdd = 10
    filoo.additional_nic = false #defaults to false. Reconfigure is not possible
  end
end
```

###Availeable OS images

The example above installs a Debian Image. Please find below the currently availeable images you can use

* Debian 6.0 - 64bit
* Endian 2.5.1 Firewall
* BalanceNG V3.3 Loadbalancer
* Ubuntu 12.04.4 LTS Server - 64bit
* CentOS 6.3 - 64bit
* Fedora 18 - 64bit
* OpenSUSE 12.3 - 64bit
* OpenSUSE 13.1 - 64bit
* Fedora 20 - 64bit
* Ubuntu 14.04 LTS Server - 64bit
* CentOS 7.0 - 64bit
* Debian 7.7 - 64bit
* Debian 7.7 - 64bit + Froxlor
* Ubuntu 15.04 Server - 64bit
* Debian 8.0 - 64bit
* OwnCloud 8.1.2 - 64 bit

###Start the machine
And finally run 'vagrant up --provider=filoo' within the folder where you have placed your Vagrantfile.
It may take a while. Once the machine has started and your FILOO_API_KEY ist set aou can yiuse the basic vagrant tools to interact with your machine:

```
$ vagrant up --provider=filoo
...#wait
$ vagrant ssh
```

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `filoo` boxes. You can view an example box in
the [example_box/ directory](<path to repository>/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Configuration

This provider exposes a few provider-specific configuration options:

* `filoo_api_key` - The api key for accessing Filoo
* `cd_image_name` - The Filoo image name to boot, such as "Debian 6.0 - 64bit"
* `filoo_api_entry_point` - The base url to the api "https://api.filoo.de/api/v1"

These can be set like typical provider-specific configuration:

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


## Development

The easiest way to setup the environment is to install ruby with the Rails Installer (http://railsinstaller.org). Also you have to install vagrant on your machine to develop the plugin

To work on the `vagrant-filoo` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

or run from your "command prompt with ruby and rails"

```
$ gem install bundler
```

in the project folder run from your "command prompt with ruby and rails"

```
$ bundle
```

If you get an ssl error follow instructions on https://gist.github.com/luislavena/f064211759ee0f806c88

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

create a box

```
$ cd example_box
$ tar cvzf filoo.box ./metadata.json ./Vagrantfile
$ mv filoo.box ../filoo.box
$ cd ..
```

Use vagrant to add the box

```
$ vagrant box add filoo.box
```

Copy the example Vagrantfile

```
cp example_config/Vagrantfile_example Vagrantfile
```

Edit your filoo api key in Vagrantfile or access Api Key via Environment Variable

```
    filoo.filoo_api_key = "your filoo api access key"
    # or to use environment variable uncomment this
    #filoo.filoo_api_key = ENV['FILOO_API_KEY']
```

Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=filoo
```

Package and publish the plugin (see https://www.noppanit.com/create-simple-vagrant-plugin/)

```
$ rake build
$ gem push pkg/vagrant_filoo-0.0.1.gem
