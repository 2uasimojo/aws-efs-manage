# aws-efs-manage
A simple utility to perform lifecycle operatons on AWS EFS volumes and access points to make them
useful/usable in a kubernetes cluster.

## Overview
Originally conceived to test the [OpenShift aws-efs-operator](https://github.com/openshift/aws-efs-operator),
I found myself using this in other contexts, so I decided to pull it out into a standalone project.

When given a `--spec` ([example](test/spec_sample.yaml), [details](#the-spec)), the `efsmanage` executable:
- Creates an ingress rule allowing NFS traffic to AWS worker nodes. (This is necessary if you
actually want to _mount_ the file systems.)
- Idempotently syncs file systems and access points according to the spec, including necessary
mount targets.

**NOTE:** As written, access points are given owner and group ID `0` (`root`) and `775`
permissions (full access to user and group, read-only access to others). These values are
currently hardcoded.

`efsmanage` uses creation tokens to allow it to track which artifacts it "owns", so you should be
able to use it without affecting other file systems and access points in your cloud. But **NO
WARRANTY** blah blah blah.

## Installation
1. Clone
2. `make efsmanage`
3. Move, link, or otherwise `$PATH` the resulting `bin/efsmanage` executable.

## Usage

```shell
[.../aws-efs-manage]$ bin/fsmanage --help
Usage: bin/fsmanage {--spec PATH | --discover | --delete-all}

  -delete-all
    	Delete all mount targets, file systems, and access points.
  -discover
    	Discover and print file system and access point pairs, one per line, e.g.
    	    fs-a99c122a:fsap-099537fb4bb7d50ea
    	    fs-b89c123b:fsap-04e855ae78fe51eed
    	    fs-b89c123b:fsap-0b02dc545c4f9b076
  -spec string
    	Path to a YAML spec file describing the desired file system and access point state.
    	The file represents a map, keyed by file system "token", of lists of access point "tokens".
    	(These tokens are arbitrary unique strings used to ensure idempotency.) For example:
    	
    	    fs1:
    	        - apX
    	    fs2:
    	        - apY
    	        - apZ
    	    fs3: []
    	
    	This will create three file systems. The first will have one access point; the second will
    	have two access points; the third will have none.

```

`efsmanage` looks for AWS credentials in all the usual places. If you're able to run the `aws` CLI,
you should be able to run `efsmanage`.

## The Spec
The argument to the `--spec` option is a path to a simple YAML file representing a map, keyed by
file system ["key"](#whats-a-key), of lists of access point ["keys"](#whats-a-key). For example,
the following YAML:

```yaml
fs1:
    - apX
fs2:
    - apY
    - apZ
fs3: []
```

...will create three file systems. The first will have one access point; the second will have two
access points; the third will have none.

### What's a key?
The "keys" in the spec file are arbitrary user-specified string values used by AWS EFS to ensure
uniqueness, idempotent creation, and identifiability of the file system or access point being
managed. (They are used to construct the file system `CreationToken` and access point
`ClientToken`.) The `efsmanage` utility also uses access point key to name the associated
subdirectory. Each key must be unique throughout the file, and probably shouldn't go crazy with
special characters. Beyond that, use whatever values you like.