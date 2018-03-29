<img width="268" src="https://raw.githubusercontent.com/lessonly/accessly/master/logo/logo.png" alt="Accessly Logo">

# Accessly

Accessly exists from our need answer the following questions:

1. What can a user do or see?
2. Can a user do an arbitrary action on another object?

We were not satisfied with the available resources to answer the questions so we created Accessly!

Accessly is our opinion of access control that allows us to broadly grant permissions to 'actors' (modeled as `users`, `groups`, `organizations`, etc)

```
Can actor1 view the content resource (/content)?
```

Our `actors` can also have permissions on other models in our application

```
Can actor1 edit a Post with id 1?
```

If you have a similar need to implement a permission scheme in your Rails app please continue reading!

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'accessly'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install accessly

Add the ActiveRecord Migrations:

    $ rails g accessly:install

## Usage

You can use the Accessly gem directly to grant | revoke | check permissions.  We recommend the use of 'Policies' which will be covered in this README
Checkout our [API docs](http://www.rubydoc.info/gems/accessly) for more info on using the API directly

### Policies

We use Accessly with policies in mind to capture everything we want to know about a specific permission set.  Let's take a look at a basic example:

```ruby
class ApplicationFeaturePolicy < Accessly::Policy::Base

  actions(
    view_dashboard: 1,
    view_super_secret_page: 2,
    edit_dashboard: 3,
    edit_super_secret_page: 4
  )

end
```

With this policy we can `grant` permissions to a user

```ruby
ApplicationFeaturePolicy.new(user).grant!(:view_super_secret_page)
```

In our `Super Secret Page` controller, we could check permissions using the `.symbol?` syntax

```ruby
ApplicationFeaturePolicy.new(user).view_super_secret_page?
```
or by using

```ruby
ApplicationFeaturePolicy.new(user).can?(:view_super_secret_page)
```

At any point in time we can revoke permissions with

```ruby
ApplicationFeaturePolicy.new(user).revoke(:view_super_secret_page)
```




## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lessonly/accessly.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
