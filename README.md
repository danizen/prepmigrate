# Prepmigrate

Crawl some URLs I need to migrate into a prototype version of a Drupal CMS,
and build XML files describing the data to go into Drupal so that these can
be processed as a Drupal migration.

## Installation

This is a project, not a module.   You check it out and use.

## Usage

There are two content types to be migrated - `page_with_sidebar` and `page`
There are two commands to do this:

    bin/build-sidebars.rb stilltodo.csv > sidebar-pages.xml
    bin/build-basics.rb stilltodo.csv > basic-pages.xml

## Contributing

Really should be private; don't contirbute but feel free to look.