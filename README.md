# buildroot-external-wrapper

The stuffs work as a wrapper to build with [buildroot] plus [br-external]
and the auxiliary scripts. The `bash` script `envsetup.sh` is the main entry
to initialize the full buildroot build environment.

Like [Android], the script can be `sourced` to load all supported functions,
and `lunch` is the function to list all supported variants built with
`defconfigs` to compile.

*NOTE: one more function `croot` is support to chdir to the top directory.*

## Reasonable br-exteranl trees

`BR2_EXTERNAL` is the key to the wrapper. How to find out the supported
br-external components is also important for the script.

The wrapper referred to [Android] implementation to detect vendor defconfigs 
in `device/*/*` and `vendor/*/*`. According to [br-external], the file
`external.desc` is the one to describe a br2-external tree. Therefore,
the directories under `device` and `vendor` containing the file `external.desc`
will be appended to `BR2_EXTERNAL` and exported.

## Supported configs

Each br2-external tree can contains its `configs` files. A valid configs file
will have `_defconfigs` as the suffix.

## Environment initialization

Every br2-external tree can contribute its stuffs to impact the build
environment with the exported functions provided by `envsetup.sh`.

- `insert_path` and `insert_path_f`

Both functions will append the following directory to the environment variable
`PATH`. `insert_path` will confirm the existence of path while `insert_path_f`
just inserts the path to the beginning of `PATH` if it's not duplicated.

- `add_lunch_combo`

It indicates the variant to lunch. Once the function `add_lunch_combo` invoked,
the auto-detection of variants in `configs` will be skipped to leave the action
to the user finally.

## Environment variables

Following variables are exported to the shell:

- `BR2_PRODUCT` - the selected variant to build
- `BR2_TOPDIR` - the top directory of project
- `BR2_BUILDDIR` - the directory `$BR2_TOPDIR/build` for original `buildroot`
- `BR2_OUTDIR` - the directory `$BR2_TOPDIR/out/` for built stuffs
- `OUT` - the similar one like `BR2_OUTDIR` without the suffix slash

To make `make` work on `BR2_TOPDIR`, an extra `Makefile` is created to include
the file `build/main.mk`, which contains simples rules to invoke `make` to
execute in `BR_BUILDDIR` for `defconfigs` target and in `BR_OUTDIR` with general
targets or implicted targets.

Within a `git-repo` project, the manifest file has to be updated to copy or
link the file to the right places:

```xml
  <project path="build/support/extra" name="buildroot_support_extra" revision="i4u/master">
    <linkfile src="envsetup.sh" dest="build/envsetup.sh"/>
    <linkfile src="main.mk" dest="build/main.mk"/>
    <copyfile src="Makefile" dest="Makefile"/>
  </project>
```

## `build-environ.py`

The file works to generate `$(PKG)_OVERRIDE_DIR` for corresponding packages
and export variables in make environment. For example, the following rules will
be globbed and converted to the actual directories and variables.

```bash
# override
$(BR2_TOPDIR)external/*

# override2
linux:$(BR2_TOPDIR)kernel
$(BR2_TOPDIR)external/busybox
```

*NOTE: `$(PKG)_OVERRIDE2_DIR` is an extension to build the package not to
synchronize the source code like `kernel` but compile in $BR2_OUTDIR/build
normally.*

[Android]: https://www.android.com
[buildroot]: https://buildroot.org
[br-external]: https://buildroot.org/downloads/manual/customize-outside-br.txt
