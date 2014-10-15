Title: Managing Node.js projects for pythonists
Date: 2014-10-15 14:00
Category: Astuces
Tags: nodejs, python, tooling
Slug: nodejs-for-pythonists
Authors: Xavier Cambar
Summary: Node.js environment for python devs

# Managing Node.js projects for pythonists

Different languages, different toolsets. Classic. Nonetheless, if you look
carefully, many tools available for language `X` are also available for
language `Y`.
This article will draft the similarities between the (core) Node.js toolset and
their equivalent in Python.

## Installation

Node.js should be installed using [NVM](https://github.com/creationix/nvm). It
is the preferred way because it allows all the packages and binaries to be
available to the current user instead of being installed system-wide.

__quick tip__: The installation process of NVM does not automatically install
Node.js. Follow
[this gist](https://gist.github.com/xcambar/2f88b912b7d40fe605c5) or the README
in the NVM repository to complete the installation process.

## Binaries

### pip

`pip` handles packages management for your projects. The equivalent in Node.js
is the `npm` command.

### python

As for the `python` command in Python-land, the `node` command is a REPL that
allows you to load execute Javascript code.

## Features comparable with Python

### virtualenv

Virtualenv in Python allows to have scoped dependencies, libraries and binaries
for a specific project.
There is no direct equivaent in Node.js, for the following reasons:

* a Node.js project (initialized with `npm init`) always has its own
    dependencies in the `node_modules` folder.
* The global dependencies (installed with `npm install -g myPackage`) are
    always scoped to the current version of Node.js you are using. That's a feature
    provided by NVM.

### requirements.txt

That file in Python-land lists all the dependencies required to run your
project. The Node.js equivalent is the file `package.json`, that is created at
the creation of your project by the `npm init` command.

When you install a dependency with `npm install --save myPackage`, the
corresponding entry is added to your `package.json`.

### pip freeze

The `pip freeze` command outputs a new `requirements.txt` file with the exact
versions of the currently used packages.
In Node-land, the equivalent command is `npm shrinkwrap`, which outputs a
`shrinkwrap.json` file which does exactly the same.

__note__: In Node, a best practice is to follow _strictly_ the conventions of
Semantic Versioning (_aka._ [SemVer](http://semver.org), which, when correctly
followed, makes the usage of `npm shrinkwrap` pretty much useless.

### pip install -e

This command lets you use a local version of a dependency that you might need
to work on (`-e` stands for _editable_). This is very useful when your project
has been decomposed in many subprojects and you want to integrate a new version
in order to publish it.

The equivalent in Node-land is `npm link` though it must be used a little bit
differently.

`npm link` declares that the current project you're in can be linked to
another.

`npm link myPackage` will use the package `myPackage` in the current project
and will use the version on which you have previously run `npm link`. Here's a
more concrete example:

```sh
$ cd myLinkedProject
$ npm link
$ cd ../myProject
$ npm link myLinkedProject
```

### setup.py

The file `setup.py` in Python is used to create project-related scripts (setup,
migration, maintenance, and so on...).

In Node.js, there are many alternatives (like, really a lot), but the simplest
is the `scripts` property in `package.json`. Here you can declare as many
scripts as you wish and use them in your projects with a simple `npm scripts
myScript` where `myScript` is a key in the `scripts` hash of your `package.json`.

__note__: As the script is defined as a value in `package.json`, it's pretty
inconvenient to write long scripts. These entries will generally use
higher-level tools to do the right job. For instance, if you want to run your
test suite and you're using `Karma`, the relevant part of your `package.json`
could look as follows:

```json
{
  "scripts": {
    "test": "node_modules/.bin/karma specs/**/*Spec.js"
  }
}
```

### Conclusion

This is definitively not an exhaustive list, there are certainly many other
similarities. But at Novapost, where we use bigger and bigger portions of the
Javascript world and are already heavily using Python, we liked to see that
best practices and good tools are shared among those two solid platforms.

By the way, we're hiring. If you're a (guess what ;) Python or (frontend) JS
developer, feel free to contact us. There are plenty of great things to do here.

