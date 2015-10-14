# vagrant-filoo
Vagrant filoo provisioner

This is a Vagrant 1.7x plugin that adds an filoo provider to Vagrant, allowing Vagrant to control and provision machines within the filoo public and private cloud.

filoo hosting: https://www.filoo.de/vserver.html

NOTE: This plugin requires Vagrant 1.7x

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `filoo` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-filoo
...
$ vagrant up --provider=filoo
...
```

Of course prior to doing this, you'll need to obtain an Filoo-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy Filoo box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy
box using any name you want:

```
$ vagrant box add dummy <url to dummy box>
...
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```
Vagrant.configure("2") do |config|
  config.vm.box = "dummy"

  config.vm.provider :filoo do |filoo, override|
    filoo.filoo_api_key = "Your Api key"
    filoo.filoo_api_entry_point = "https://api.filoo.de/api/v1/"
    filoo.cd_image_name = "Debian 6.0 - 64bit"

    filoo.cd_image_name = "Debian 6.0 - 64bit"
    override.ssh.username = "debian"
    override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
  end
end
```

And then run `vagrant up --provider=filoo`.

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

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the FILOO provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

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