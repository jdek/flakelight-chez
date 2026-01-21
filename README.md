# flakelight-chez

Chez Scheme module for [flakelight][1].

[1]: https://github.com/nix-community/flakelight

Package metadata can be read from an optional `manifest.scm` file.

## Options

`chezPackage` allows changing the Chez Scheme package used. It can be set to a
function that takes the package set and returns a Chez Scheme package.

`chezLibraries` allows adding Chez Scheme libraries that the project depends on.
Set it to a function that takes the package set and returns a list of packages.

`chezProgram` specifies the main program file to compile/install. Defaults to
`main.ss` or the value specified in `manifest.scm`.

`chezCompile` controls whether to compile the Scheme code to native code.
Defaults to `true`.

## Configured options

Sets `package` to build the Chez Scheme project at the flake source.

Adds Chez Scheme to the default devShell, along with any libraries specified in
`chezLibraries`.

Configures Scheme files (`.ss`, `.scm`, `.sls`) to be formatted.

## Example flakes

### Standard

```nix
{
  description = "My Chez Scheme application.";
  inputs.flakelight-chez.url = "github:accelbread/flakelight-chez";
  outputs = { flakelight-chez, ... }: flakelight-chez ./. {
    license = "MIT";
  };
}
```

### With manifest.scm

Create a `manifest.scm` file with metadata:

```scheme
((name "my-app")
 (version "1.0.0")
 (program "main.ss"))
```

Then use the flake:

```nix
{
  description = "My Chez Scheme application.";
  inputs.flakelight-chez.url = "github:accelbread/flakelight-chez";
  outputs = { flakelight-chez, ... }: flakelight-chez ./. {
    license = "MIT";
  };
}
```

### With dependencies

```nix
{
  description = "My Chez Scheme application.";
  inputs.flakelight-chez.url = "github:accelbread/flakelight-chez";
  outputs = { flakelight-chez, ... }: flakelight-chez ./. {
    license = "MIT";
    chezLibraries = pkgs: [ pkgs.chez-srfi ];
  };
}
```
