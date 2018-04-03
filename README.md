<img width="268" src="https://raw.githubusercontent.com/lessonly/accessly/master/logo/logo.png" alt="Accessly Logo">

# Accessly

Accessly exists out of our need to answer the following questions:

1. What can a user do or see?
2. Can a user do an arbitrary action on another object?

We were not satisfied with the available resources to answer the questions so we created Accessly!

Accessly is our opinion of access control that can broadly grant permissions to 'actors' (modeled as `users`, `groups`, `organizations`, etc)

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

You can use the Accessly gem directly to grant | revoke | check permissions.  We recommend the use of 'Policies' covered in this README.
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
# or
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
    edit: 2,
    destroy: 3
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
it may be necessary to override the default behavior represented in the above example.

Accessly can return a relation of ids on an object for a given actor's permission grants.  `Accessly::Policy::Base` requires
that you implement `self.model_scope` with an `ActiveRecord` scope so the `list` api can return an `ActiveRecord::Relation`

With this policy we can `grant` permissions for a user to do an action on another user object.

```ruby
UserPolicy.new(user).grant!(:edit, other_user)
```

In our `EditUserController`, we can check permissions

```ruby
UserPolicy.new(user).edit?(other_user)
# or
UserPolicy.new(user).can?(:edit, other_user)
```

We can list all of the users available to edit with

```ruby
UserPolicy.new(user).edit
# or
UserPolicy.new(user).list(:edit)
```

At any point in time we can revoke permissions with

```ruby
UserPolicy.new(user).revoke(:edit, other_user)
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
    edit: 2,
    destroy: 3,
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

Accessly policies can extend support for combined use of `actions` and `actions_on_objects.` You may want to broadly grant `edit_basic_info` permissions to some users. The same policy can support a limited scope of permissions where the `actor` and `object` must be defined.

#### segment_id

`segment_id` allows you to scope permission grants to a specific object id that you define. In our example the `actor` belongs to an Organization model, and we set the organization_id on each permission granted for any actor using the policy.

It provides additional efficiency on query execution, and we can broadly remove permissions if the organization is no longer in the application.

#### unrestricted?

Accessly uses `unrestricted?` to bypass permission checks. This policy shows that the actor has an `admin` designation which we do not want to model in permissions. The business logic implemented here would bypass any permission check if `unrestricted?` returns `true`. When `unrestricted?` returns `true`, then `can?` and the other permission check methods (like `edit_basic_info?` in this example) automatically return `true`, and `list` and the other list methods (like `edit` in this example) returns the `ActiveRecord::Relation` given by `self.model_scope`

### Advanced Action Policy

Let's look at a policy that overrides `action?` and `list` APIs

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
    edit: 2,
    destroy: 3
  )

  def self.namespace
    User.name
  end

  def self.model_scope
    User.all
  end

  # Override the destroy permission check for an "Action on Object"
  def destroy?(object)
    if actor.name == "Alice"
      true
    else
      super
    end
  end

  # Override the view permission check for both Action only and "Action on Object"
  def view?(object = nil)
    if object.nil?
      if actor.name == "Bob"
        false
      else
        super
      end
    elsif actor.name == "Alice" && object.name == "Bob"
      true
    else
      super
    end
  end

  # Override the change_role check for Action only
  def change_role?
    false
  end

  # Override the list method for view permissions
  def view
    if actor.name == "Alice"
      User.all
    else
      super
    end
  end
end
```
#### Overriding defaults

Here we provide some examples of the `Accessly::Policy::Base` overrides you can make in an application. You can override the function completely or fallback to the `Base` method. The implementation strategy is up to you!

Any call to the following functions will run the given example in the policy:

#### destroy?(object)

```ruby
# Action on Object queries
UserPolicy.new(user).destroy?(other_user)
# or
UserPolicy.new(user).can?(:destroy, other_user)
```

#### view?(object = nil)

```ruby
# Action queries
UserPolicy.new(user).view?
# or
UserPolicy.new(user).can?(:view)

# Action on Object queries
UserPolicy.new(user).view?(other_user)
# or
UserPolicy.new(user).can?(:view, other_user)
```

#### change_role?

```ruby
# Action queries
UserPolicy.new(user).change_role?
# or
UserPolicy.new(user).can?(:change_role)
```

#### view

```ruby
# List queries
UserPolicy.new(user).view
# or
UserPolicy.new(user).list(:view)
```

## Caching

Accessly implements some internal caching to increase the performance of permission queries. If you use the same Policy object for the same lookup twice, then the second one will lookup based on the cached result. Be mindful of caching when using `revoke!` or `grant!` calls with subsequent permission queries on the same Policy object.


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/lessonly/accessly.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
