# VALA-SCP

A convenience library for file transfers via SCP for vala applications

## Setup
Clone github repo into the main project folder
```
$ git clone https://github.com/moroen/vala-scp.git
```

or as a git submodule:

```
$ git submodule add https://github.com/moroen/vala-scp.git
$ git submodule init
$ git submodule update
```

## Adding to meson.build

```
inc = include_directories('vala-scp')
subdir('vala-scp')

dependencies = [
    dependency('glib-2.0'),
    dependency('gobject-2.0'),
]

sources = files(...)

app = executable('...', sources, 
    include_directories: inc,
    dependencies: dependencies, 
    link_with: scp_lib)

```
## Usage

### Receive file
```
scp transfer = new scp("remoteIP", "remoteUserName", "remotePassword", "localFileName", "remoteFileName");

ssize_t bytes = transfer.receive ();
```
### Send file
```
scp transfer = new scp("remoteIP", "remoteUserName", "remotePassword", "localFileName", "remoteFileName");

ssize_t bytes = transfer.send ();
```

### Overriding show_progress
```
class custom_scp: scp {
    public myscp(string host, string username, string password, string local_path, string remote_path) {
        base(host, username, password, local_path, remote_path);
    }

    public override void show_progress(ssize_t current, ssize_t total) {
        stdout.printf("%s of %s\n", current.to_string(), total.to_string()); 
    }
}
```

