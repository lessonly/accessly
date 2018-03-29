<img width="268" src="https://raw.githubusercontent.com/lessonly/accessly/master/logo/logo.png" alt="Accessly Logo">

# Accessly

Accessly exists from our need to answer the following questions:

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

You can use the Accessly gem directly to grant | revoke | check permissions.  We recommend the use of 'Policies' which will be covered in this README.
Checkout our [API docs](http://www.rubydoc.info/gems/accessly) for more info on using the API directly

We use Accessly with policies in mind to capture everything we want to know about a specific permission set. Let's take a look at some examples:

### Basic Action Policy

```ruby
class ApplicationFeaturePolicy < Accessly::Policy::Base

  actions(
    view_dashboard: 1,
    view_super_secret_page: 2,
    view_double_secret_probation_page: 3
  )

end
```

With this policy we can `grant` permissions to a user

```ruby
ApplicationFeaturePolicy.new(user).grant!(:view_super_secret_page)
```

In our `SuperSecretPageController`, we can check whether the user has permission to view that page with

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

### Basic Action on Object Policy

We can grant permissions to `actors` on other `objects` in our application with a policy like:

```ruby
class UserPolicy < Accessly::Policy::Base

  actions_on_objects(
    view: 1,
    edit_basic_info: 2,
    change_role: 3,
    email: 4
  )

  def self.namespace
    User.name
  end

  def self.model_scope
    User.all
  end
end
```

We differentiate permissions by a `namespace` which by default is the name of your policy class.  However,
It may be necessary to override the default behavior represented in the above example.

Accessly can return a relation of ids on an object for a given actor's permission grants.  `Accessly::Policy::Base` requires
that you implement `self.model_scope` with an `ActiveRecord` scope so the `list` api can return an `ActiveRecord::Relation`

With this policy we can `grant` permissions for a user to do an action on another user object.

```ruby
UserPolicy.new(user).grant!(:edit_basic_info, other_user)
```

In our `Edit User` controller, we can check permissions

```ruby
UserPolicy.new(user).edit_basic_info?(other_user)
```
or by using

```ruby
UserPolicy.new(user).can?(:edit_basic_info, other_user)
```

We can list all of the users available to edit with

```ruby
UserPolicy.new(user).edit_basic_info
```
or by using

```ruby
UserPolicy.new(user).list(:edit_basic_info)
```

At any point in time we can revoke permissions with

```ruby
UserPolicy.new(user).revoke(:edit_basic_info, other_user)
```

### Intermediate Action Policy

Let's look at a policy with a combined configuration and more customization

```ruby
class UserPolicy < Accessly::Policy::Base

  actions(
    view: 1,
    edit_basic_info: 2,
    change_role: 3,
    email: 4
  )

  actions_on_objects(
    view: 1,
    edit_basic_info: 2,
    change_role: 3,
    email: 4
  )

  def self.namespace
    User.name
  end

  def self.model_scope
    User.all
  end

  def segment_id
    actor.organization_id
  end

  def unrestricted?
    actor.admin?
  end
end
```

This policy combines `actions` and `actions_on_objects`, introduces Accessly's support for `segment_id`, and overrides `unrestricted?`

#### combined actions and actions_on_objects

Accessly policies can extend support for combined use of `actions` and `actions_on_objects.`  You may want to broadly grant `edit_basic_info` permissions to some users.  The same policy can support a limited scope of permissions where the `actor` and `object` must be defined.

#### segment_id

`segment_id` allows you to scope permission grants to a specific object id that you define.  
In our example the `actor` belongs to an Organization model, and we set the organization_id on each permission granted for any actor using the policy.

It provides additional efficiency on query execution, and we can broadly remove permissions if the organization is no longer in the application.

#### unrestricted?

Accessly uses `unrestricted?` to bypass permission checks.  This policy shows that the actor has an `admin` designation which we do not want to model in permissions.  The business logic implemented here would bypass any permission check if `unrestricted?` returns `true`

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lessonly/accessly.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
