require 'spec_helper'

require File.join(Rails.root, 'lib', 'has_person_proxy')

describe HasPersonProxy do
  describe 'setup' do
    before do
      @person = HasPersonProxy::DeletedPersonProxy.new
    end

    it 'should respond_to name ' do
      @person.name.should == 'Diaspora User'
    end

    it 'has a nil owner_id' do
      @person.owner_id.should be nil
    end

    it 'returns an empty string for anything else' do
      @person.alsdkfsdl.should == ''
    end

    it 'should log objects with nil people' do
      Rails.logger.should_receive(:info)
      HasPersonProxy::DeletedPersonProxy.new(Factory(:status_message))
    end
  end

  describe 'including it into objects' do 
    before do
      class HasPerson < Statistic
        include HasPersonProxy
        always_has_one_person

        def id
          2
        end
      end

      class NilPerson < Statistic
        include HasPersonProxy
        always_has_one_person

        def id
          4
        end

        def person_id
          34232 #this doesnt exsist
        end
      end
    end

    it 'returns a person object if one exsists' do
      has_person = HasPerson.new
      has_person.person = Factory(:person)
      has_person.person.should be_a Person
    end

    it 'returns a person object if one exsists' do
      nil_person = NilPerson.new
      nil_person.person.should be_a HasPersonProxy::DeletedPersonProxy
    end
  end
end
