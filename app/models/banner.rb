class Banner < ActiveYamlBase

  field :visible, default: true

  self.singleton_class.send :alias_method, :all_with_invisible, :all

  class << self

    def all
      all_with_invisible.select &:visible
    end

  end
end
