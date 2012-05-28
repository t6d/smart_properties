# SmartProperties

Ruby accessors on steroids.

## Installation

Add this line to your application's Gemfile:

    gem 'smart_properties'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install smart_properties

## Usage

`SmartProperties` are meant to extend standard Ruby classes. Simply include
the `SmartProperties` module and use the `property` method along with a name
and optional configuration parameters to define new properties. Calling this
method results in the generation of a getter and setter pair. In contrast to
traditional Ruby accessors -- created by calling `attr_accessor`,
`SmartProperties` provide much more functionality:

1. input conversion,
2. input validation,
3. default values, and
4. presence checking.

These features can be configured by calling the `property` method with
additional configuration parameters. The module also provides a default
implementation for a constructor that accepts a set of attributes. This is
comparable to the constructor of `ActiveRecord` objects.

Before we discuss the configuration of properties in more detail, we first
present a short synopsis of all the functionality provided by
`SmartProperties`.

### Synopsis

The example below shows how to implement a class called `Message` which has
three properties: `subject`, `body`, and `priority`. The two properties,
`subject` and `priority`, are required whereas `body` is optional.
Furthermore, all properties use input conversion. The `priority` property also
uses validation and has a default value.

    class Message
      property :subject,  :converts => :to_s
      
      property :body,     :converts => :to_s
      
      property :priority, :converts => :to_sym, 
                          :accepts  => [:low, :normal, :high],
                          :default  => :normal
                          :required => true
    end
    
Creating an instance of this class without specifying any attributes will
result in an `ArgumentError` telling you to specify the required property
`subject`.

    Message.new # => raises ArgumentError, "Message requires the property subject to be set"

Providing the constructor with a title but with an invalid value for the
property `priority` will also result in an `ArgumentError` telling you to
provide a proper value for the property `priority`.

    m = Message.new :subject => 'Lorem ipsum'
    m.priority # => :normal
    m.priority = :urgent # => raises ArgumentError, Message does not accept :urgent as value for the property priority

Next, we discuss the various configuration options `SmartProperties` provide.

### Property Configuration

This subsection explains the various configuration options `SmartProperties`
provide.

#### Input conversion

To automatically convert a given value for a property, you can use the
`:converts` configuration parameter. The parameter can either be a `Symbol` or
a `lambda` statement. Using a `Symbol` will instruct the setter to call the
method identified by this symbol on the object provided as input data and take
the result of this method call as value instead. The example below shows how
to implement a property that automatically converts all given input to a
`String` by calling `#to_s` on the object provided as input.

    class Article
      property :title, :converts => :to_s
    end

If you need more fine-grained control, you can use a lambda statement to
specify how the conversion should be done. The statement will be evaluated in
the context of the class defining the property and takes the given value as
input. The example below shows how to implement a property that automatically
converts all given input to a slug representation.

    class Article
      property :slug, :converts => lambda { |slug| slug.downcase.gsub(/\s+/, '-').gsub(/\W/, '') }
    end

#### Input validation

To ensure that a given value for a property is always of a certain type, you
can specify the `:accepts` configuration parameter. This will result in an
automatic validation whenever the setter for a certain property is called. The
example below shows how to implement a property which only accepts instances
of type `String` as input.

    class Article
      property :title, :accepts => String
    end

Instead of using a class, you can also use a list of permitted values. The
example below shows how to implement a property that only accepts `true` or
`false` as values.

    class Article
      property :published, :accepts => [true, false]
    end

You can also use a `lambda` statement for input validation if a more complex
validation procedure is required. The `lambda` statement is evaluated in the
context of the class that defines the property and receives the given value as
input. The example below shows how to implement a property called title that
only accepts values which match the given regular expression.

    class Article
      property :title, :accepts => lambda { |title| /^Lorem \w+$/ =~ title }
    end

#### Default values

There is also support for default values. Simply use the `:default`
configuration parameter to configure a default value for a certain property.
The example below demonstrates how to implement a property that has 42 as
default value.

    class Article
      property :id, :default => 42
    end

#### Presence checking

To ensure that a property is always set set and never `nil`, you can use the
`:required` configuration parameter. If present, this parameter will instruct
the setter of a property to not accept nil as input. The example below shows
how to implement a property that may not be `nil`.

    class Article
      property :title, :required => true
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
