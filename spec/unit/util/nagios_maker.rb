#!/usr/bin/env ruby
#
#  Created by Luke Kanies on 2007-11-18.
#  Copyright (c) 2007. All rights reserved.

require File.dirname(__FILE__) + '/../../spec_helper'

require 'puppet/util/nagios_maker'

describe Puppet::Util::NagiosMaker do
    before do
        @module = Puppet::Util::NagiosMaker

        @nagtype = stub 'nagios type', :parameters => [], :namevar => :name
        Nagios::Base.stubs(:type).with(:test).returns(@nagtype)
    end

    it "should be able to create a new nagios type" do
        @module.should respond_to(:create_nagios_type)
    end

    it "should fail if it cannot find the named Naginator type" do
        Nagios::Base.stubs(:type).returns(nil)

        lambda { @module.create_nagios_type(:no_such_type) }.should raise_error(Puppet::DevError)
    end

    it "should create a new RAL type with the provided name prefixed with 'nagios_'" do
        type = stub 'type', :newparam => nil, :newproperty => nil, :ensurable => nil, :provide => nil

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should mark the created type as ensurable" do
        type = stub 'type', :newparam => nil, :newproperty => nil, :provide => nil

        type.expects(:ensurable)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should create a namevar parameter for the nagios type's name parameter" do
        type = stub 'type', :newproperty => nil, :ensurable => nil, :provide => nil

        type.expects(:newparam).with(:name, :namevar => true)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should create a property for all non-namevar parameters" do
        type = stub 'type', :newparam => nil, :ensurable => nil, :provide => nil

        @nagtype.stubs(:parameters).returns([:one, :two])

        type.expects(:newproperty).with(:one)
        type.expects(:newproperty).with(:two)
        type.expects(:newproperty).with(:target)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should skip parameters that start with integers" do
        type = stub 'type', :newparam => nil, :ensurable => nil, :provide => nil

        @nagtype.stubs(:parameters).returns(["2dcoords".to_sym, :other])

        type.expects(:newproperty).with(:other)
        type.expects(:newproperty).with(:target)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should deduplicate the parameter list" do
        type = stub 'type', :newparam => nil, :ensurable => nil, :provide => nil

        @nagtype.stubs(:parameters).returns([:one, :one])

        type.expects(:newproperty).with(:one)
        type.expects(:newproperty).with(:target)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end

    it "should create a target property" do
        type = stub 'type', :newparam => nil, :ensurable => nil, :provide => nil

        type.expects(:newproperty).with(:target)

        Puppet::Type.expects(:newtype).with(:nagios_test).returns(type)
        @module.create_nagios_type(:test)
    end
end

describe Puppet::Util::NagiosMaker, " when creating the naginator provider" do
    before do
        @module = Puppet::Util::NagiosMaker

        @nagtype = stub 'nagios type', :parameters => [], :namevar => :name
        Nagios::Base.stubs(:type).with(:test).returns(@nagtype)

        @type = stub 'type', :newparam => nil, :ensurable => nil, :newproperty => nil
        Puppet::Type.stubs(:newtype).with(:nagios_test).returns(@type)
    end

    it "should add a naginator provider" do
        @type.expects(:provide).with { |name, options| name == :naginator }

        @module.create_nagios_type(:test)
    end

    it "should set Puppet::Provider::Naginator as the parent class of the provider" do
        @type.expects(:provide).with { |name, options| options[:parent] == Puppet::Provider::Naginator }

        @module.create_nagios_type(:test)
    end

    it "should use /etc/nagios/$name.cfg as the default target" do
        @type.expects(:provide).with { |name, options| options[:default_target] == "/etc/nagios/nagios_test.cfg" }

        @module.create_nagios_type(:test)
    end
end
