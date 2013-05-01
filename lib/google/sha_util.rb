module Google
  module ShaUtil
    extend self
    
    SHA256 = OpenSSL::Digest::SHA256.new
    
    def sha256_hex str, prefix = nil
      hash = sha256_digest(str).unpack("H64").first
      if prefix
        hash.first(prefix)  # first 'prefix' chars
      else
        hash
      end
    end
    
    def sha256_digest str
      SHA256.digest(str)
    end
    
    
  end
end