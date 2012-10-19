# Duple

Duple makes it easy to move PostgreSQL data around between your deployment
environments. Duple knows how to move data from one heroku environment to
another and how to load it into your local database. It can execute rake or
Heroku commands before and after your loading data into your target
environment. This is great for scrubbing, replacing, trimming or generating
data for your test environments.

## Installation

Install the gem:

    $ gem install duple

Generate a config file:

    $ duple init

## Configuration

The generated config file contains samples of all the different ways you can
figure the application. Read and modify it, or clear it out and write your own.

## Usage

    # Resets the stage database
    # Loads the latest production snapshot into the stage database
    $ duple refresh production stage

    # Downloads the latest full snapshot from production
    # Resets the development database
    # Loads the snapshot into the development database
    $ duple refresh production development

    # Captures a new production database snapshot
    # Downloads the latest full snapshot from production
    # Resets the development database
    # Loads the snapshot into the development database
    $ duple refresh production development --capture

    # Downloads the schema and a subset of data from stage
    # Resets the backstage database
    # Loads the structure and the subset into the backstage database
    $ duple refresh stage backstage --group minimal

    # Downloads the data from the specified tables from the stage database
    # Loads the data into the backstage database
    $ duple copy stage backstage --tables products categories

## Future

  * Everything.
  * Support for skipping pre- and post- refresh steps.
  * Support for running pre- and post- refresh steps by themselves.
  * Support for other data stores.

## Contributing

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Add some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request
