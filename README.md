# Extlib

## Overview

This document describes how to set up a local Perl library that holds
snapshotted and patched versions of various CPAN modules, ensuring
that our application is using the same code across all machines.

This is done by downloading and installing modules from CPAN to extlib/
and then using extlib/ as the primary Perl path via local::lib.

This uses methods taken from Carton. You should probably use that unless
you need the features in Extlib.


## Howto: Quickstart

    # Install to extlib/
    ./extlib/install


## Howto: Do a full clean install

    # Clear old directories
    rm -rf extlib/{var,bin,lib,man} OR make extlib-clean-all

    # Run install
    ./extlib/install


## Howto: Update all (unpinned) packages to latest CPAN version

Note: This process *at best* will require you to install all the
the packages in the extlib multiple times. Do not do this expecting
that it will be fast. There is no way to do this
in a good way that doesn't require that. It's also very possible that
you will need to debug problems with newly updated packages. If you
only want to add or update one package, see the section below on
how to do that. It's probably a lot less work.

    # update extlib/etc/modules.yaml with any new packages

    # install code needed, if not already done
    ./extlib/build-blib

    # execute the update script, saving to a log
    ./extlib/update-src  |& tee update-src.log

    # you probably will need to examine the output to make sure that
    # everything installed ok

    # you may need to re-install a package with
    ./extlib/update-package My::Module

    # Debug. Various errors in packaging might cause issues, sometimes necessary
    # to handle by patching. Do various checks of the current vs installed modules
    ./extlib/check-update

    # Build the 02packages.details.tar.gz file, extlib.json, and distfiles.txt
    # Note: if there are pinned packages that require removing the non-pinned
    # current versions, if the removed versions have prereqs that are not needed
    # by any other package, you will have to run build-metadata & verify-update twice,
    # to remove the dangling dependencies
    ./extlib/build-metadata

    # verify updates by cleaning out the local lib, installing fresh,
    # and comparing against what extlib.json thinks ought to be there
    ./extlib/verify-update  |& tee verify-update.log

    # Note: you must do some testing.
    # Just because everything installs, doesn't mean it still works. It's pretty
    # common for a new package to break things in odd ways, and then we have to pin
    # and report, or sometimes patch. *Always* open upstream bugs, if one doesn't
    # already exist, and be sure to put comments in modules.yaml explaining the
    # reason for the pin and how we will know that it can be unpinned. Don't make
    # people do a 'blame' on modules.yaml and chase you down.

    # If everything worked, you can now commit to source control.
    ./extlib/make-commit-message


## Howto: Update or add a single package to latest CPAN version without updating
  everything.
  Note: this will update its dependencies too...

WARNING: Plan on doing this from an updated master branch and commit early because
git offers no direct way to resolve conflicts in binary files that get changed
in this process.  If need be, then cherry pick that into your branch.

    # Add it to extlib/etc/modules.yaml, if new

    Either do:
        # NOTE: this is a more thorough method and will cover some situations
        # where update-src-fast will fail

        # Add/install thepackage
        ./extlib/update-src-single Some::Module Some::Other::Module

        # update the metadata
        ./extlib/build-metadata

        # verify the update by freshly installing
        ./extlib/verify-update

     OR do:
        # NOTE: this will fail in some situations, such as if it is a new
        # package with prereqs that were not previously installed that you
        # have already installed into your system perl.

        # Fast update-src does build-metadata too
        ./extlib/update-src-fast Some::Module

    #  If everything worked, commit to source control
    #  IN particular, make sure that new prereqs have actually installed, since
    #  that is one of the most likely failure points
    #  Make sure that extlib.json contains entries for your new package

    ./extlib/make-commit-message


## Committing to source control

    # use the provided script. It will do the git add, create the
    # commit message, and prompt you to do the actually commit.
    # Note: does not add changes to the Extlib code and scripts
    ./extlib/make-commit-message


## Howto: Pin a CPAN package to a specific version

    In extlib/etc/modules.yaml, add a 'path:' entry, e.g.:

      My::Module:
        path: AUTHOR/My-Module-0.1.tar.gz

    Then run "Update all..." or "Update single..."  above.

Please note why and when the package was pinned in modules.yaml; this will
help when someone in the future tries to decide if it's safe to unpin the
package yet or not.


## Howto: use a patched version or a local distribution (not on CPAN)

Find the source package, and untar it somewhere.
Apply your patches, and make sure to change the version anywhere it
exists in the source code (you need to make sure the version is
greater than the original source, but less than the next version to
be released). This includes the various META files, the .pm package itself,
and the Makefile.PL/Build.PL. It's common to use a 'development' version
number for this, which is an appended underscore and a number, so that
0.33 becomes 0.33_1. If the meta in the distribution has a 'release_status'
it must be set to 'testing'.

Tar up the new code. The directory and the tarfile should have the
new version.

    Either:
        1) Copy the new tarfile into extlib/src/authors.
        2) Update extlib/src/modules/02packages.details.txt.gz with an entry for
        your new source package. (It won't be found in our local lib without it.)
    or:
        Use OrePAN or OrePAN2

In extlib/etc/modules.yaml, add a value for 'path' that points to
the package source file.

    Run:

    extlib/update-src or extlib/update-src-single or extlib/update-src-fast
    extlib/verify-update

Commit the changes as described in "Committing to source control".

NOTE: if the changes are suitable for general consumption, then consider
sending patches upstream to the author for their consideration.  (Most
packages seem to be on github at this point; this makes a
patch/fork/pull-request nearly trivial.)  Merging fixes/etc upstream is in
everyone's best interests: makes the CPAN and that package better, and
eliminates the our overhead in maintaining (what are essentially) forked
packages.


## Reference: extlib/ directory

Description of the layout and files of extlib/:

    * extlib/blib/lib/perl5/Extlib.pm

      Code used to build the mirror and install

    * extlib/src

      A local CPAN mirror, this holds package source files that we've
      downloaded (or patched/created ourselves).

    * extlib/lib, extlib/bin, extlib/man

      These are directories to which the modules eventually get
      installed to, and used by local::lib.

    * extlib/update-src

      Script that parses extlib/etc/modules.yaml, runs cpanm to
      install the packages to extlib/lib, and does --save-dist to
      save the distribution archives to extlib/src.

    * extlib/install

      Installs from our src directory into our lib/bin/man directories.

    * extlib/etc/modules.yaml

      Master list of the modules we need, along with metadata about
      how to install them.  Big enough to warrant its own Reference
      section below.

    * extlib/etc/distfiles.txt

      Created by extlib/update-src. This is a
      list of all the packages we are going to install. Not
      currently used by the build process, but might be useful as
      a place to track changes in installed distributions.
      Currently it's in alphabetic order. It used to be in installation
      order.

    * extlib/var/last-install-results.json

      Results of the last time extlib/install was successfully run.
      Used to no-op the script if it gets run again without any
      changes to extlib/etc/distfiles.txt


## Reference: extlib/etc/modules.yaml

A YAML file that holds all the modules we need to run our
application.  A module can have extra metadata needed to
download/install it, including the following:

    path -  Use a specific (i.e. pinned) path for this module.  Should
            be in the format AUTHOR/package.tar.gz

            extlib/update-src uses this to ensure that we don't download
            a newer package source file from CPAN.

            'path' with no additional flag, means this module is pinned.
            'path' with 'patched' flag means we patched it.
            'path' with 'local' flag means that this package is not on CPAN


    force - Note that a module is failing to install, but we've determined
            that's OK and we want to force install it.

            Used by extlib/update-src.

    patched, local

            Flags to say what flavor of 'path' this is (if not simply pinned)

    notest - with a distribution
            If we do a testing run, run this one with --notest. By default
            we don't test at the moment, which is the way that carton works.

All attributes of a module should be documented in comments, preferrably with the
name of the person who's establishing the limitation. Please be sure to comment
why the package was forced (or pinned), with links to any cpantesters, RT, github
issues or pull requests that may be available.  If anything non-obvious is causing
necessitating the force, please note it.

