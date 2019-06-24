class Level < ActiveYamlBase

  def self.enumerize
    all.inject({}) {|hash, i| hash[i.key.to_sym] = i.id; hash}
  end

end
