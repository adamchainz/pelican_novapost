Title: Thou shalt polyfill
Date: 2014-10-27 14:00
Category: Astuces
Tags: frontend, polyfill
Slug: thou-shalt-polyfill
Authors: Xavier Cambar
Summary: Polyfills help your project move forward

# Thou shalt polyfill

Recently, I had a look at a JSConf 2014 talk by Sebastian Markbage (engineer at
Facebook and TC39 member) on
["minimal surface APIs"](http://2014.jsconf.eu/speakers/sebastian-markbage-minimal-api-surface-area-learning-patterns-instead-of-frameworks.html).
What is that? Why does it require an article?

## tl;dr;

Use polyfills instead of limiting yourself with tools that embed the required
set of backward-compatible machinery.

## What is a minimal surface API?

First off, API here is not to be understood in the REST sense of the term.
We're talking software API, like the number of methods and mechanisms you need
to know to achieve a particular goal.

A minimal surface API requires you to forget about the differences of
implementation. But it should not be taken for abstraction, because too often,
abstraction itself adds entropy to APIs. Sebastian gives the perfect example of
`Underscore`, that makes you use `_.each` or `_.map` when
`Array.prototype.forEach` and `Array.prototype.map` already exist.
This is too complicated a solution. According to Sebastian Markbage (which I
humbly second here), a better solution would have been to monkey patch
`Array.prototype`, despite what we've heard and/or read in the past about
monkey patching native prototypes in JS.

## Why is it important?

Though we love the "Move the Web forward" trend, that tends to explicitly
display to outdated browsers' users a message stating that they could "browse
happy" (understood as "you'd better change your computer"), a __lot__ of
companies have to deal with hundreds if not thousands of (sometimes) very old
computers, alongside very heavy security measures that prevent them form being
able to update to the latest version of Chrome/Firefox (what else?).

We're not discussing their choices here, but we're facing a fact: You can't
force your users to use your favorite browser. Period.

But it would be a shame to limit yourself to outdated browsers and prevent the
more "technologically advanced" of your users to enjoy the niceties they embed,
right?

Solution: Polyfill.

You don't have to assume that all your users are using sh\*\*ty browsers, just
make it so they all get as many _decent_ APIs as possible.
That will make for a better experience for the users of modern browsers and it
will also ease the transition when you won't need to use a particular polyfill
anymore.

In a word, polyfills favor graceful degradation to progressive enhancement.

## How do I...

### Know if feature X is cross-browser?

Go to [caniuse.com](http://caniuse.com). It's a complete matrix of browsers and
features.

You can and should also refer to the
[MDN](https://developer.mozilla.org/en-US/docs/Web) which provide
compatibility matrices for JS and CSS as well as atomic polyfills when they
exist.

### Know if such a feature is available at runtime?

Use [Modernizr](http://modernizr.com/), it will let you load your polyfills
only if needed. Though most polyfills will already do this part of the job, it
allows to have a clear in-app context of what's possible and eventually switch
solutions based on what's been detected (_eg_. Why load a touch API on a
desktop?). Indispensable.

### Find the correct polyfill?

[Modernizr](http://modernizr.com/) offers
[a dedicated wiki page](https://github.com/Modernizr/Modernizr/wiki/HTML5-Cross-Browser-Polyfills)
with an impressive number of polyfills for most of the features it covers.
In the most extreme cases, Google "xyz polyfill", go to github and you'll
certainly find what you're looking for.

## Conclusion

A minimal surface API is an API where there are no two single functions that
do the same thing. Take care of it for your sanity, for the clarity of your
code and for your project to be kept updated, because polyfills are meant to be
removed after some time, after all, right?

This approach has been in the running at Facebook for quite some time; for
instance, React is built with the EcmaScript 6 syntax. There are other projects
that follow this track, as [Ember](http://emberjs.com), which we're using
greatly here.

If you're in line with the contents of this article and want to have a chat
with us, feel free to ping us, we're always available... and hiring :)

