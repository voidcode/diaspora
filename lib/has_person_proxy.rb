module HasPersonProxy
  module ClassMethods
    def always_has_one_person
      puts "doing pretty well"
        has_one :person
      self.instance_eval do
        extend InstanceMethods
        alias_method_chain :person, :proxy
      end
    end

    def always_belongs_to_person
        belongs_to :person
      self.instance_eval do
        puts "doing pretty"
       extend InstanceMethods
      end
    end
  end

  module InstanceMethods
    def person_with_proxy
      puts "yah yah"
      self.person_without_proxy || DeletedPersonProxy.new(self)
    end
  end
  
  class DeletedPersonProxy 
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

