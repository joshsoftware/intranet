module Mongoid
  module Document
    def serializable_hash(options = nil)
      hash = super(options)
      hash['id'] = hash.delete('_id') if(hash.has_key?('_id'))
      hash
    end
  end
end
