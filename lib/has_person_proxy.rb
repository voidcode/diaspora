module HasPersonProxy
  module ClassMethods
    def always_has_one_person
      self.instance_eval do
        has_one :person
        include InstanceMethods
        alias_method_chain :person, :proxy
      end
    end

    def always_belongs_to_person
      self.instance_eval do
        belongs_to :person
        include InstanceMethods
        alias_method_chain :person, :proxy
      end
    end
  end

  module InstanceMethods
    def person_with_proxy
      self.person_without_proxy || DeletedPersonProxy.new(self)
    end
  end
  
  class DeletedPersonProxy < Person
    def initialize(object=nil)
      unless object.nil?
        Rails.logger.info("event=person_proxy object=#{object.class} object_id=#{object.id} deleted_person_id=#{object.person_id} ")
      end
      @empty = ''
    end


    def name
      'Diaspora User'
    end

    def owner_id
      nil
    end

    def method_missing(*args)
      @empty
    end
  end

  def self.included(base)
    base.class_eval do
      base.extend ClassMethods
    end
  end
end

